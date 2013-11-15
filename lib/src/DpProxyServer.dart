/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of dicerati_proxy;

class DpProxyServer extends DpTcpServer {
  
  
  /**
   * The in memory database
   */
  DpDatabase _database;
  
  DpProxyServer(String host,
                int port,
                this._database) : super(host,port){
    
    log.info("Starting Proxy server on ${host}:${port}...");
    
  }
  
  /**
   * Responder override
   */
  void responder(HttpRequest request) {
    
    Uri incomingUri = request.uri;
    
    /**
     * Check the host header, if the host is us then this is a response to one of our
     * HTTP client requests, respond to the request and add CORS headers
     */
    if ( (request.headers.host == HOST) && ( request.headers.port == PROXY_SERVER_PORT) ) {
      
      print(request.headers);
      log.info("Headers are :- $request.headers");
    }
    /**
     * This is a dicearati client request, get the details for the proxy request 
     * check for success, if OK send to the target server.
     */
    String hostAddress = request.connectionInfo.remoteAddress.address;
    Map proxyDetails = _database.getProxyDetails(hostAddress);
    if ( proxyDetails[DpDatabase.SUCCESS] ) {
      
      /**
       * Look for an options request, if we have one add the CORS headers
       * and return the response
       */
      if ( request.method == 'OPTIONS') {
        
        request.response.headers.set(HttpHeaders.CONTENT_TYPE, "text/plain; charset=UTF-8");
        request.response.headers.add("Access-Control-Allow-Origin", "*");
        List methodList = ["GET", "POST", "PUT", "OPTIONS", "DELETE", "HEAD", "COPY"];
        request.response.headers.add("Access-Control-Allow-Methods", methodList);
        request.response.headers.add("Access-Control-Allow-Credentials", "true");
        List allowHeadersList = ["Content-Type", "Authorization", "Destination"];
        request.response.headers.add('Access-Control-Allow-Headers', allowHeadersList);
        request.response.close();
        return;
      }
      
      /**
       * Get the incoming URI and build the outgoing URI from
       * the proxy details.
       */  
      String path = incomingUri.path;
      Map hostDetails = proxyDetails[DpDatabase.DETAILS];
      Map incomingParams = incomingUri.queryParameters;
      Uri outgoingUri = new Uri(scheme: hostDetails[DpDatabase.SCHEME],
                              host: hostDetails[DpDatabase.PROXY],
                              port: hostDetails[DpDatabase.PORT],
                              path:path,
                              queryParameters:incomingParams);
      
      /**
       * Create a HTTP Client to perform the proxy request
       * Catch any and all exceptions.
       */
      HttpClient client = new HttpClient();
      client.openUrl(request.method, 
                     outgoingUri).
      then((HttpClientRequest clientRequest) {
        
        /**
         * Prepare the request then call close on it to send it.
         */
        clientRequest.headers.contentType = request.headers.contentType;    
        clientRequest.addStream(request.take(request.contentLength));
        return clientRequest.close();
        
       }).then((HttpClientResponse response) {
         
         /**
          *  Get the response body 
          */
          List body = new List<int>();
          response.listen(
            (data) => body.addAll(data),
            
            onDone: () {
              
              /**
               * Write the body back to the requestor with 
               * specific recieved headers.
               */
              response.headers.forEach((name, value) {
                
                if ( name == 'www-authenticate') {
                  
                  request.response.headers.add(name, value);
               
                }
                
                if ( name == 'server') {
                  
                  request.response.headers.add(name, value);
               
                }
                
                if ( name == 'content-type') {
                  
                  request.response.headers.add(name, value);
               
                }
                
                
              });
                
              /**
                * CORS
                */
              request.response.headers.add("Access-Control-Allow-Origin", "*");
              List methodList = ["GET", "POST", "PUT", "OPTIONS", "DELETE", "HEAD", "COPY"];
              request.response.headers.add("Access-Control-Allow-Methods", methodList);
              request.response.headers.add("Access-Control-Allow-Credentials", "true");
              List allowHeadersList = ["Content-Type", "Authorization", "Destination"];
              request.response.headers.add('Access-Control-Allow-Headers', allowHeadersList);
              
              request.response.add(body);
              request.response.close();
              _database.statisticsUpdateSuccess();
              
            },
            
            onError: (e) {
            
            log.severe("Proxy Server - Proxy response error [${e.toString()}]");
            closeOnError(request,
                         HttpStatus.SERVICE_UNAVAILABLE);
            _database.statisticsUpdateFailed();
            
          });
          
        }).catchError((e) {
          
          log.severe("Proxy Server - HTTP Client error [${e.toString()}]");     
          closeOnError(request,
                       HttpStatus.SERVICE_UNAVAILABLE);
          _database.statisticsUpdateFailed();
        
        });
          
    
    } else {
      
      /**
       * No proxy details, should never happen, send error status, log the error 
       */
      log.severe("Proxy Server - No proxy details for [${incomingUri}]");
      closeOnError(request,
                   HttpStatus.SERVICE_UNAVAILABLE);
      _database.statisticsUpdateFailedNoEntry();
      
      
    }
  }
  
  void handleError(e) {
    
    log.severe("Proxy Server - fatal error - server has crashed");
    log.severe("Proxy Server - error is[${e.toString()}]");
    
  }
  
  void closeOnError(HttpRequest request,
                    int statusCode) {
    
    request.response.statusCode = HttpStatus.SERVICE_UNAVAILABLE;
    request.response.write('Deserati Proxy is unavailable for this request!');
    request.response.close();
    
  }
  
  
}
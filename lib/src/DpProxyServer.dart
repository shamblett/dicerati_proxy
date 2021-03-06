/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 * 
 * The main proxy server class, this takes the incoming client
 * request, removes and checks the CLID then re-builds the outgoing
 * URL. It adds CORS headers when needed and manages the proxy request
 * from start to finish.
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
    
    /**
     * Get the incoming Uri, the first segment of the path is our CLID
     */
    Uri incomingUri = request.uri;
    String CLID;
    try {
    
      CLID = incomingUri.pathSegments[0];
    
    } catch(e) {
      
      /**
       * No CLID, fail the request but add the CORS headers
       */
      request.response.headers.set(HttpHeaders.CONTENT_TYPE, "text/plain; charset=UTF-8");
      request.response.headers.add("Access-Control-Allow-Origin", "*");
      List methodList = ["GET", "POST", "PUT", "OPTIONS", "DELETE", "HEAD", "COPY"];
      request.response.headers.add("Access-Control-Allow-Methods", methodList);
      request.response.headers.add("Access-Control-Allow-Credentials", "true");
      List allowHeadersList = ["Content-Type", "Authorization", "Destination"];
      request.response.headers.add('Access-Control-Allow-Headers', allowHeadersList);
      log.severe("Proxy Server - No CLID supplied for [${request.connectionInfo.remoteAddress.toString()}]");
      closeOnError(request,
                   HttpStatus.BAD_REQUEST);
      _database.statisticsUpdateFailedNoEntry();
      return;
      
    }
    /**
     * Get the details for the client request, check for success, 
     * if OK send to the proxy server or process an OPTIONS request.
     */ 
    Map proxyDetails = _database.getProxyDetails(CLID);
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
      Map hostDetails = proxyDetails[DpDatabase.DETAILS];
      String path = buildProxyPath(incomingUri,
                                   hostDetails);
      
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
      HttpClient proxy = new HttpClient();
      proxy.openUrl(request.method, 
                     outgoingUri).
      then((HttpClientRequest proxyRequest) {
        
        /**
         * Prepare the request by copying any headers and body data we may have 
         * into it then call close on it to send it, finally. process 
         * the response.
         */
        request.headers.forEach((name, value) {
          
          proxyRequest.headers.add(name, value); 
          
        });
        
        /**
         * Host and content length
         */
        proxyRequest.headers.set('host',hostDetails[DpDatabase.PROXY]);                               
        proxyRequest.contentLength = request.contentLength;
        
        request.forEach((e) {
           
           proxyRequest.add(e);
           
         }).then((r) => proxyRequest.close()).
          then((HttpClientResponse response) {
         
         /**
          *  Get the response body 
          */
          List body = new List<int>();
          response.listen(
            (data) => body.addAll(data),
            
            onDone: () {
              
              /**
               * Write the body back to the client with 
               * the recieved data from the proxy
               */
              
              /**
               * Status codes.
               */
              request.response.statusCode = response.statusCode;
              request.response.reasonPhrase = response.reasonPhrase;
              
              /**
                * CORS
              */  
              request.response.headers.add("Access-Control-Allow-Origin", "*");
              List methodList = ["GET", "POST", "PUT", "OPTIONS", "DELETE", "HEAD", "COPY"];
              request.response.headers.add("Access-Control-Allow-Methods", methodList);
              request.response.headers.add("Access-Control-Allow-Credentials", "true");
              List allowHeadersList = ["Content-Type", "Authorization", "Destination"];
              request.response.headers.add('Access-Control-Allow-Headers', allowHeadersList);
              
              /**
               * Body length must not exceed content length, if it does
               * trim it. Note content length must be valid, ie not -1
               */
              if ( (response.contentLength > -1) &&
                  (body.length > response.contentLength) ) {        

                body.removeRange(response.contentLength,        
                                 body.length);

              }

              
              /**
               * Headers
               */
               response.headers.forEach((name, value) {
                
                request.response.headers.add(name, value);      
                          
               });

              /**
               * Write the body and close the response
               */
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
        
      });
    
    } else {
      
      /**
       * No proxy details, should never happen, send error status, log the error 
       */
      log.severe("Proxy Server - No proxy details for [${incomingUri}]");
      closeOnError(request,
                   HttpStatus.BAD_REQUEST);
      _database.statisticsUpdateFailedNoEntry();
      
      
    }
  }
  
  void handleError(e) {
    
    log.severe("Proxy Server - fatal error - server has crashed");
    log.severe("Proxy Server - error is[${e.toString()}]");
    
  }
  
  /**
   * Close the request in the event of an error
   */
  void closeOnError(HttpRequest request,
                    int statusCode) {
    
    request.response.statusCode = statusCode;
    request.response.write('Dicerati Proxy is unavailable for this request!');
    request.response.close();
    
  }
  
  /**
   * Build the proxy path from the incoming url and the details
   * from CouchDB.
   */
  String buildProxyPath(Uri uri,
                        Map details) {
    
    /**
     * Remove the CLID from the path
     */
    List segments = new List.from(uri.pathSegments);
    segments.removeAt(0);
    
    /**
     * Return as a string
     */
    return segments.join('/');
    
  }
  
  
}
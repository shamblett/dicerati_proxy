/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpProxyServer extends DpTcpServer {
  
  
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
     * Get the details for the proxy request and check for success
     */
    JsonObject proxyDetails = _database.getProxyDetails(request.connectionInfo.remoteHost);
    if ( proxyDetails.success) {
      
      /**
       * Get the incoming URI and build the outgoing URI from
       * the proxy details.
       */  
      String path = incomingUri.path;
      Map incomingParams = incomingUri.queryParameters;
      Uri outgoingUri = new Uri(scheme: proxyDetails.details.scheme,
                              host: proxyDetails.details.proxy,
                              port: proxyDetails.details.port,
                              path:path,
                              queryParameters:incomingParams);
      
      /**
       * Create a HTTP Client to perform the proxy request
       * Catch any and all exceptions.
       */
      
      HttpClient client = new HttpClient();
      client.getUrl(outgoingUri).then((HttpClientRequest request) {
        
        /**
         * Prepare the request then call close on it to send it.
         */
        return request.close();
        
       }).then((HttpClientResponse response) {
         
         /**
          *  Get the response body 
          */
          StringBuffer body = new StringBuffer();
          String theResponse;
          response.listen(
            (data) => body.write(new String.fromCharCodes(data)),
            
            onDone: () {
              
              /**
               * Write the body back to the requestor
               */
              theResponse = body.toString();
              request.response.write(theResponse);
              request.response.close();
            },
            
            onError: (e) {
            
            log.severe("Proxy Server - Proxy response error [${e.toString()}]");
            closeOnError(request,
                         HttpStatus.SERVICE_UNAVAILABLE);
            
          });
          
        }).catchError((e) {
          
          log.severe("Proxy Server - HTTP Client error [${e.toString()}]");     
          closeOnError(request,
                       HttpStatus.SERVICE_UNAVAILABLE);
        
        });
          
    
    } else {
      
      /**
       * No proxy details, should never happen, send error status, log the error 
       */
      log.severe("Proxy Server - No proxy details for [${incomingUri}]");
      closeOnError(request,
                   HttpStatus.SERVICE_UNAVAILABLE);
      
      
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
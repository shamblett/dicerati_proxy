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
  
  void responder(HttpRequest request) {
    
    JsonObject details = _database.getProxyDetails(request.connectionInfo.remoteHost);
    if ( details.success) {
      
      HttpClient client = new HttpClient();
      Uri incomingUri = request.uri;
      String path = incomingUri.path;
      Map incomingParams = incomingUri.queryParameters;
      Uri outgoingUri = new Uri(scheme: details.details.scheme,
                              host: details.details.proxy,
                              port: details.details.port,
                              path:path,
                              queryParameters:incomingParams);
      client.getUrl(outgoingUri)
      .then((HttpClientRequest request) {
        // Prepare the request then call close on it to send it.
        return request.close();
        })
        .then((HttpClientResponse response) {
          StringBuffer body = new StringBuffer();
          String theResponse;
          response.listen(
            (data) => body.write(new String.fromCharCodes(data)),
            onDone: () {
              theResponse = body.toString();
              request.response.write(theResponse);
              request.response.close();
            });
          
        });
    
    } else {
      
      if ( !details.waiting ) {
        
        log.severe("Oops, no proxy details found");
        request.response.close();
        
       } else {
         
        Uri redirector = Uri.parse('http://127.0.0.1/8080');
        request.response.redirect(redirector, status:HttpStatus.TEMPORARY_REDIRECT);
      }
    }
  }
}
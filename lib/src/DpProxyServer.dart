/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpProxyServer extends DpTcpServer {
  
  
  DpProxyServer(String host,
                int port) : super(host,port){
    
    log.info("Starting Proxy server on ${host}:${port}...");
    
  }
  
  void responder(HttpRequest request) {
    
    HttpClient client = new HttpClient();
    Uri incomingUri = request.uri;
    Map incomingParams = incomingUri.queryParameters;
    String path = incomingUri.path;
    Uri outgoingUri = new Uri(scheme:'http',
                              host:'141.196.22.210',
                              port:5984,
                              path:path,
                              queryParameters:incomingParams);
    client.getUrl(outgoingUri)
      .then((HttpClientRequest request) {
        // Prepare the request then call close on it to send it.
        return request.close();
      })
        .then((HttpClientResponse response) {
          print(response.contentLength);
          print(response.headers.toString());
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
    
    
    
  }
}
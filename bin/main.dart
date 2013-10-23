
import 'dart:io';
//import 'dart:convert';
import 'dart:async';

final HOST = "127.0.0.1";
final SERVER_PORT = 8080;
final MANAGEMENT_PORT = 9001;


class TCPServer {
  
  TCPServer(host,port) {
    
    print("Starting TCP server on ${host}:${port}...");
    HttpServer.bind(host,port).then((HttpServer server) {
      server.listen(responder);
    });
     
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

void main() {
  
  TCPServer tcpserver = new TCPServer(HOST,SERVER_PORT);
}

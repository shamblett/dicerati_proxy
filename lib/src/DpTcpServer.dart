/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of dicerati_proxy;

abstract class DpTcpServer {
  
  /**
   * Host
   */
  String _host;
  get host => _host;
  
  /**
   * Port
   */
  int _port;
  get port => _port;
  
  DpTcpServer(this._host,
              this._port) {
    
    HttpServer.bind(host,port).then((HttpServer server) {
      server.serverHeader = SERVER_HEADER;
      server.listen(responder, onError:handleError);
    }).catchError(handleError);;
     
  }
  
  /**
   * Derived classes must supply a responder
   */
  void responder(HttpRequest request){}
  
  /**
   * Derived classes must supply an error handler
   */
  void handleError(e) {} 
    
}
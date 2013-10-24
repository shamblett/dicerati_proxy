/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

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
  
  
  /**
   * Simple constructor
   */
  DpTcpServer(this._host,
              this._port) {
    
    HttpServer.bind(host,port).then((HttpServer server) {
      server.listen(responder);
    });
     
  }
  
  /**
   * Derived classes must supply a responder
   */
  void responder(HttpRequest request){}
  
}
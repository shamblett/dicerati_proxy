/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpManagementServer extends DpTcpServer {
  
  DpDatabase _database;
  
  DpManagementServer(String host,
                     int port,
                     this._database) : super(host,port){
    
    log.info("Starting Management server on ${host}:${port}...");
    
  }
  
  void responder(HttpRequest request) {
    
    request.response.write('This is the Management Server!');
    request.response.close();
    
  }
  
  void handleError(e) {
    
    log.severe("Management Server - fatal error - server has crashed");
    log.severe("Proxy Server - error is[${e.toString()}]");
  }
  
  void closeOnError(HttpRequest request,
                    int statusCode) {
    
    request.response.statusCode = HttpStatus.SERVICE_UNAVAILABLE;
    request.response.write('Deserati Proxy is unavailable for this request!');
    request.response.close();
    
  }
  
}
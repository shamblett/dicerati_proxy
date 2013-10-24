/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpManagementServer extends DpTcpServer {
  
  
  DpManagementServer(String host,
                     int port) : super(host,port){
    
    log.info("Starting Management server on ${host}:${port}...");
    
  }
  
  void responder(HttpRequest request) {
    
  }
  
}
/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpManagementServer extends DpTcpServer {
  
  /**
   * The in memory database
   */
  DpDatabase _database;
  
  /**
   * The management class
   */
 DpManagement _manager;
  
 /**
  * Mustache variable object 
  */
 JsonObject _mustacheVars = new JsonObject();
 
 DpManagementServer(String host,
                     int port,
                     this._database) : super(host,port){
    
    log.info("Starting Management server on ${host}:${port}...");
    _manager = new DpManagement();
    
  }
 
  /**
   * Responder override
   */
  void responder(HttpRequest request) {
    
    /**
     * Switch on the method, if POST its a command, otherwise just get
     * the home page
     */
    switch (request.method) {
      
      case 'POST': 
        
        doCommand(request);
        break;
      
      default: doNormal(request);
    }
     
  }
  
  /**
   * Normal, none command processing
   */
  void doNormal(HttpRequest request) {
    
    String contents = _manager.renderHTML(_mustacheVars);
    request.response.write(contents);
    request.response.close();
    
  }
  
  /**
   * Command processing
   */
  void doCommand(HttpRequest request) {
    
    StringBuffer body = new StringBuffer();
    String commandRequest;
    request.listen(
        (data) => body.write(new String.fromCharCodes(data)),
        
        onDone: () {
          
          /**
           * Get the command body as parameters
           */
          commandRequest= body.toString();
          var parameters = Uri.splitQueryString(commandRequest);
          
          /**
           * Check the parameters, if failed return the page with the 
           * appropriate alert.
           */
          String alertBlock;
          bool paramsOk = _manager.checkUpdateParameters(parameters,
                                                         alertBlock);
          if ( paramsOk ) {
            
            _database.addProxyDetailsFromCommand(parameters);
            returnSuccessCommand();
            
          } else {
            
            returnFailedCommand(alertBlock,
                                parameters);
            
          }
          
         
          JsonObject retVal = new JsonObject.fromMap(parameters);
          _mustacheVars = retVal;
          doNormal(request);
         
          
        },
        
        onError: (e) {
          
        log.severe("Management Server - Command decode failed [${e.toString()}]");
        closeOnError(request,
            HttpStatus.SERVICE_UNAVAILABLE);
        
      }); 
    
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
  
  
  
  void returnFailedCommand(String alertBlock,
                           Map parameters) {
    
    
    
    
  }
  
  void returnSuccessCommand() {
    
    
    
    
  }
  
}
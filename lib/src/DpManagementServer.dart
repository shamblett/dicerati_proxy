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
     * Switch on the method, if POST its a command, otherwise get
     * the home page or whatever the path says.
     */
    switch (request.method) {
      
      case 'POST': 
        
        doCommand(request);
        break;
        
      case 'GET':
        
        /**
         * Look for a path
         */
      if ( request.uri.pathSegments.length > 0 ) {
        
        String filePath = resolveUriPath(request);
        doPath(request,
               filePath);
      
      } else {
      
        doNormal(request);
        
      }
      break;
      
      default: doNormal(request);
    }
     
  }
  
  /**
   * Normal, none command processing
   */
  void doNormal(HttpRequest request) {
    
    String contents = _manager.renderHTML(null);
    request.response.write(contents);
    request.response.close();
    
  }
  
  /**
   * Path, none command processing
   */
  void doPath(HttpRequest request,
              String filePath) {
    
    if ( filePath != NO_PATH ) {
      
      File entity = new File(filePath); 
      List<int> contents = entity.readAsBytesSync();
      request = addHeaders(request);
      request.response.add(contents);
       
    }
    
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
           * appropriate alert, otherwise update the database
           */
          String alertBlock;
          alertBlock  = _manager.checkUpdateParameters(parameters);
          if ( alertBlock != null  ) {
            
            _database.updateFromCommand(parameters);
            
          }
            
          returnCommand(alertBlock,
                        parameters,
                        request);
                 
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
  
  void returnCommand(String alertBlock,
                     Map parameters,
                     HttpRequest request) {
    /**
     * Check for success
     */
    if (alertBlock == null ) alertBlock = _manager.getAlertBlock(DpManagement._SUCCESS);
    
    /**
     * Check the command
     */
    if ( parameters['dpCommand'] == 'add' ) {
      
      parameters['dp-add-alert'] = alertBlock;
      
    } else {
      
      parameters['dp-remove-alert'] = alertBlock;
    }
   
    String contents = _manager.renderHTML(parameters);
    request.response.write(contents);
    request.response.close();
    
  }
  
  String resolveUriPath(HttpRequest request) {
    
    List pathList = request.uri.pathSegments;
    
    switch ( pathList[0] ) {
      
      case 'images' :
        
        return IMAGES + pathList[1];
        break;
      
      default :
        
        return NO_PATH;
     
    }    
    
  }
  
  HttpRequest addHeaders(HttpRequest request) {
    
   HttpRequest retRequest = request; 
   List pathList = request.uri.pathSegments;
    
   switch ( pathList[0] ) {
      
      case 'images' :
    
        retRequest.response.headers.add('Content-Type',
                                     'image/png');
        break;
     }
    
    return retRequest; 
    
  }
  
}
/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpDatabase {
  
  /**
   * CouchDb host
   */
  String _host;
  get host => _host;
  
  /**
   * Database name
   */
  String _dbName;
  get dbName => _dbName;
  
  /**
   * The HTTP client
   */
  HttpClient _client = new HttpClient();
  
  /**
   * The changes HTTP client
   */
  HttpClient _changesClient = new HttpClient();
  
  /**
   * The in memory database
   */
  Map<String,Map> _database;
    
  DpDatabase(this._host,
             this._dbName,
             this._database) {
    
  }
  
  /**
   * Get the proxy details for a remote host
   */
  Map getProxyDetails(String remoteHost) {
    
    Map returnVal = new Map();
    returnVal['success'] = false;
    
    if ( _database.containsKey(remoteHost) ) {
      
      returnVal['success'] = true;
      returnVal['details'] = _database[remoteHost];
      
    } 
    
    return returnVal;
      
    
  }
  
  /**
   * Set the proxy details for a remote host
   */
  bool setProxyDetails(String remoteHost,
                       Map details) {
      
    Map entry = new Map<String,Object>();
    entry['proxy'] = details['proxy'];
    entry['port'] = details['port'];
    entry['scheme'] = details['scheme'];
    _database[remoteHost] = entry;
    
  }
 
  /**
   * Remove the proxy details for a remote host
   */
  bool removeProxyDetails(String remoteHost) {
      
    _database.remove(remoteHost);
  }
  
  /**
   * Initialise the in memory database from CouchDB
   */
  void initialise() {
    
    String path = "$_dbName/_all_docs?include_docs=true";
    _client.get(COUCH_HOST, 5984, path)
      .then((HttpClientRequest request) {
        return request.close();
      })
        .then((HttpClientResponse result) {
          
          StringBuffer body = new StringBuffer();
          String theResponse;
          result.listen(
              (data) => body.write(new String.fromCharCodes(data)),
              
              /**
               * Ok, complete
               */
              onDone: () {
                
                theResponse = body.toString();
                /**
                 * Update the database
                 */
                //JsonObject documents = new JsonObject.fromJsonString(theResponse);
                Map documents = JSON.decode(theResponse);
                documents['rows'].forEach((document) {
                  
                  setProxyDetails(document['id'],
                                  document['doc']);
                  
                });
                
              },
              
              /**
               * Error, log the error
               */
              onError: (e) {
                
                log.severe("Initialise database  HTTP fail, reason [${result.reasonPhrase}], code [${result.statusCode}]");
                            
              }); 
          
        });
  }
  
  /**
   * Update the database from a command
   */
  updateFromCommand(Map parameters) {
    
    String remoteHost = parameters['dp-host-ip'];
    
    switch(parameters['dpCommand']) {
      
      case 'add' :
        
        Map hostParameters = new Map();
        hostParameters['proxy'] = parameters['dp-proxy-url'];
        hostParameters['port'] = int.parse(parameters['dp-port']);
        hostParameters['scheme'] = parameters['dp-scheme'];
        setProxyDetails(remoteHost,
                        hostParameters);
        log.info("Added proxy details for host name $remoteHost");
        
        break;
        
      case 'remove' :
        
        removeProxyDetails(remoteHost);
        log.info("Removed proxy details for host name $remoteHost");
        break;
    }
    
  }
  
  //TODO
  void monitorChanges() {
    

    String path = "$_dbName/_changes?feed=continuous?include_docs=true";
    String url = "http://$COUCH_HOST:5984/$path";
    Uri uri = Uri.parse(url);
    HttpClientRequest theRequest = null;
    _changesClient.openUrl('GET', uri)
      .then((HttpClientRequest request) {
        
        theRequest = request;
        //request.close();
        //return request.done;
        
      });
      var completion = theRequest.flush();
      completion.then(
       (data) => print(data)    
      
      );
      
        
        /*.whenComplete(() {
          
          StringBuffer theBody = new StringBuffer();
          String theResponse = null;

          theRequest.done.asStream().forEach((element){
            var body = element.toList();
            body.asStream().listen(
                (data) => theBody.write(new String.fromCharCodes(data)),
            
            onDone:
              theResponse = body.toString()
                
            );
          })
          .whenComplete(() {
            
            
            /**
             * Update the database
             */
            if ( theResponse != "" ) {
              JsonObject changes = new JsonObject.fromJsonString(theResponse);
              print(changes);
            }
          });
          
            
      });     */
          
  }
  
}
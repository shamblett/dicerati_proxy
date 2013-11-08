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
   * the CouchDB 'since' update marker
   */
  int _since = 0;
  
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
  
  void monitorChanges() {
    
    String path = "$_dbName/_changes?include_docs=true&since=$_since";
    String url = "http://$COUCH_HOST:5984/$path";
    Uri uri = Uri.parse(url);
    _changesClient.openUrl('GET', uri)
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
                 * Process the change request
                 */
                  Map dbChanges = JSON.decode(theResponse);
                  if ( dbChanges.containsKey('last_seq') ) {
                    
                    _since = dbChanges['last_seq'];
                  
                  } else {
                    
                    processDbChanges(dbChanges);
                  
                  }
              },
              
              /**
               * Error, log the error
               */
              onError: (e) {
                
                log.severe("Monitor Changes  HTTP fail, reason [${result.reasonPhrase}], code [${result.statusCode}]");
                            
              }); 
          
        });
      
  }
  
  /**
   * Database change update
   */
  void processDbChanges(Map changes) {
    
    /**
     * if _since is 0 this is the first time round, we just need to get
     * the last seq number and update _since otherwise process the update and
     * update _since
     */
    
    /**
     * Deconstruct the input
     */
    List results = changes['results'];
    int lastSince = _since;
    
    results.forEach((result) {
      
      if ( _since != 0 ) {
        
        processDbChange(result);
        
      }
      
      lastSince  = result['seq'];
     
    });
    
    _since = lastSince;
    
  }
  
  void processDbChange(Map change ) {
    
    print(change);
    
  }
  
  void changeTest() {
    
    _changesClient.getUrl(Uri.parse("http://$HOST/db/_changes?feed=continuous"))
      .then((request) => request.close())
      .then((response) => response.listen(print));  
  }
  
}
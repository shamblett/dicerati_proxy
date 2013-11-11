/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpDatabase {
  
  /**
   * Static field names
   */
  static final PROXY = 'proxy';
  static final SCHEME = 'scheme';
  static final PORT = 'port';
  static final SUCCESS = 'success';
  static final DETAILS = 'details';
  static final STAT_KEY = 'statistics';
  static final STAT_SUCCESS = 'success';
  static final STAT_FAIL = 'failed';
  static final STAT_FAIL_NOENTRY = 'failedNoEntry';
  
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
   
 /**
  * Statistics
  */
  get statistics => _database['statistics'];
  
  DpDatabase(this._host,
             this._dbName,
             this._database) {
    
  }
  
  /**
   * Get the proxy details for a remote host
   */
  Map getProxyDetails(String remoteHost) {
    
    Map returnVal = new Map();
    returnVal[SUCCESS] = false;
    
    if ( _database.containsKey(remoteHost) ) {
      
      returnVal[SUCCESS] = true;
      returnVal[DETAILS] = _database[remoteHost];
      
    } 
    
    return returnVal;
      
    
  }
  
  /**
   * Set the proxy details for a remote host
   */
  bool setProxyDetails(String remoteHost,
                       Map details) {
      
    Map entry = new Map<String,Object>();
    entry[PROXY] = details[PROXY];
    entry[PORT] = details[PORT];
    entry[SCHEME] = details[SCHEME];
    _database[remoteHost] = entry;
    
  }
 
  /**
   * Remove the proxy details for a remote host
   */
  bool removeProxyDetails(String remoteHost) {
      
    if ( _database.containsKey(remoteHost) ) {
      
      _database.remove(remoteHost);
      
    }
    
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
    
    /**
     * Add the statistics keys
     */
    Map stats = new Map<String,int>();
    stats[STAT_SUCCESS] = 0;
    stats[STAT_FAIL] = 0;
    stats[STAT_FAIL_NOENTRY] = 0;
    _database[STAT_KEY] = stats;
    
  }
  
  /**
   * Update the database from a command
   */
  updateFromCommand(Map parameters) {
    
    String remoteHost = parameters['dp-host-ip'];
    
    switch(parameters['dpCommand']) {
      
      case 'add' :
        
        Map hostParameters = new Map();
        hostParameters[PROXY] = parameters['dp-proxy-url'];
        hostParameters[PORT] = int.parse(parameters['dp-port']);
        hostParameters[SCHEME] = parameters['dp-scheme'];
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
                 * Process the change request, update since
                 */
               
                Map dbChanges = JSON.decode(theResponse);
                processDbChanges(dbChanges);
                _since = dbChanges['last_seq'];
                  
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
   * Database change update processing
   */
  void processDbChanges(Map changes) {
    
    /**
     * if _since is 0 this is the first time round we can ignore the changes
     * as we have just initialised, otherwise process the update.
     */
    
    if ( _since == 0 ) return;
    
    /**
     * Deconstruct the input
     */
    List results = changes['results'];
    results.forEach((result) {
            
        processDbChange(result);     
    });
    
    
  }
  
  /**
   * Single change update
   */
  void processDbChange(Map change ) {
      
    Map document = change['doc'];
    if ( !change.containsKey('deleted') ) {  
    
      Map details = new Map(); 
      details[PROXY] = document[PROXY];
      details[PORT] = document[PORT];
      details[SCHEME] = document[SCHEME];
      
      log.info("Database update recieved for proxy $document['_id']");
      removeProxyDetails(document['_id']);
      setProxyDetails(document['_id'],
                      details);
      
    } else {
      
      log.info("Database delete recieved for proxy $document['_id']");
      removeProxyDetails(document['_id']);
      
    }
    
  }
  
  /**
   * Statistics update success
   */
  void statisticsUpdateSuccess() {
    
    Map stats = _database[STAT_KEY];
    stats[STAT_SUCCESS]++;
    _database[STAT_KEY] = stats;
    
  }
  
  /**
   * Statistics update failed
   */
  void statisticsUpdateFailed() {
    
    Map stats = _database[STAT_KEY];
    stats[STAT_FAIL]++;
    _database[STAT_KEY] = stats;
    
  }
  
  /**
   * Statistics update failed no entry
   */
  void statisticsUpdateFailedNoEntry() {
    
    Map stats = _database[STAT_KEY];
    stats[STAT_FAIL_NOENTRY]++;
    _database[STAT_KEY] = stats;
    
  }
  
  //TODO
  /*void changeTest() {
    
   
  }*/
  
}
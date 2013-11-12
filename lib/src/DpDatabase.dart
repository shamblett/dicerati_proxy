/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of dicerati_proxy;

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
   * Couch first change marker
   */
  bool _firstChange = true;
  
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
    
    String path = "$_dbName/_changes?feed=continuous&heartbeat=1000&include_docs=true";
    String url = "http://$COUCH_HOST:5984/$path";
    Uri uri = Uri.parse(url);
    _changesClient.openUrl('GET', uri)
      .then((HttpClientRequest request) {
        return request.close();
      })
      .then((HttpClientResponse result) {
                  
          result.listen(
              (data) {
                
                StringBuffer body = new StringBuffer();
                String theResponse;
                /**
                 * Main processing is here in listen, not in onDone as
                 * this connection never closes
                 */
                body.write(new String.fromCharCodes(data));
                theResponse = body.toString();
                /**
                 * Process the change request, 
                 */
                if ( theResponse.length == 1 ) {
                  
                  /**
                   * Heartbeat from Couch, reset firstChange
                   */
                  _firstChange = false;
                  
                } else {
                  
                  /**
                   * Real change update, ignore if first change, otherwise
                   * process the change.
                   */
                  if ( _firstChange ) return;
                  
                  Map dbChange = JSON.decode(theResponse);
                  processDbChange(dbChange);
                  
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
  void processDbChange(Map change ) {
      
    Map document = change['doc'];
    if ( !change.containsKey('deleted') ) {  
    
      Map details = new Map(); 
      details[PROXY] = document[PROXY];
      details[PORT] = document[PORT];
      details[SCHEME] = document[SCHEME];
      
      log.info("Database update recieved for proxy $document");
      removeProxyDetails(document['_id']);
      setProxyDetails(document['_id'],
                      details);
      
    } else {
      
      log.info("Database delete recieved for proxy $document");
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
  
}
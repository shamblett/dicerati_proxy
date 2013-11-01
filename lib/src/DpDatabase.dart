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
  JsonObject getProxyDetails(String remoteHost) {
    
    JsonObject returnVal = new JsonObject();
    returnVal.success = false;
    
    if ( _database.containsKey(remoteHost) ) {
      
      returnVal.success = true;
      JsonObject details = new JsonObject.fromMap(_database[remoteHost]);
      returnVal.details = details;
      
      
    } 
    
    return returnVal;
      
    
  }
  
  /**
   * Set the proxy details for a remote host
   */
  bool setProxyDetails(String remoteHost,
                      JsonObject details) {
      
    Map entry = new Map();
    entry['proxy'] = details.proxy;
    entry['port'] = details.port;
    entry['scheme'] = details.scheme;
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
                JsonObject documents = new JsonObject.fromJsonString(theResponse);
                documents.rows.forEach((document) {
                  
                  setProxyDetails(document.id,
                                  document.doc);
                  
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
  
  addProxyDetailsFromCommand(Map parameters) {
    
    
  }
}
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
   * The in memory database
   */
  Map<String,Map> _database;
  
  DpDatabase(this._host,
             this._dbName) {
    
    _database = new Map<String,Map>();
    
    Map details = new Map();
    details['proxy'] = '141.196.22.210';
    details['scheme'] = 'http';
    details['port'] = 5984;
    
    _database['127.0.0.1'] = details;
    
  }
  
  JsonObject getProxyDetails(String remoteHost) {
    
    JsonObject returnVal = new JsonObject();
    returnVal.success = false;
    
    if ( _database.containsKey(remoteHost) ) {
      
      returnVal.success = true;
      JsonObject details = new JsonObject.fromMap(_database[remoteHost]);
      returnVal.details = details;
      return returnVal;
      
    }
    
  }
    
  bool setProxyDetails(String remoteHost,
                      JsonObject details) {
      
    
  }
 
  bool removeProxyDetails(String remoteHost) {
      
    
  }
 

}
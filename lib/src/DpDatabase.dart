/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpDatabase {
  
  
  /**
   * The in memory database
   */
  Map<String,Map> _database;
    
  DpDatabase(this._database) {
    
  }
  
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
    
  bool setProxyDetails(String remoteHost,
                      JsonObject details) {
      
    
  }
 
  bool removeProxyDetails(String remoteHost) {
      
    
  }
  

}
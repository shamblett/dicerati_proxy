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
  
  /**
   * The HTTP client
   */
  HttpClient _client = new HttpClient();
  
  
  DpDatabase(this._host,
             this._dbName) {
    
    _database = new Map<String,Map>();
    
  }
  
  JsonObject getProxyDetails(String remoteHost) {
    
    JsonObject returnVal = new JsonObject();
    returnVal.success = false;
    returnVal.waiting = false;
    
    /**
     * In memory first, else go to Couch
     */
    if ( _database.containsKey(remoteHost) ) {
      
      returnVal.success = true;
      JsonObject details = new JsonObject.fromMap(_database[remoteHost]);
      returnVal.details = details;
      return returnVal;
      
    } else {
      
      returnVal.waiting = true;
      
      /** 
        * Make the Couch request     
        */
       String path = "$_dbName/$remoteHost";
       _client.get(_host, 5984, path)
       .then((HttpClientRequest request) {
            return request.close();
        })
         
        /**
          * Get the response
          */
        .then((HttpClientResponse response) {
           
           StringBuffer body = new StringBuffer();
           String theResponse;
           response.listen(
               (data) => body.write(new String.fromCharCodes(data)),
               /**
                * Ok, complete
                */
               onDone: () {
                 
                 theResponse = body.toString();
                 /**
                  * Update the in memory database
                  */
                 JsonObject details = new JsonObject.fromJsonString(theResponse);
                 Map dbDetails = new Map();
                 details.forEach((key,value) {
                   
                   dbDetails[key] = value;
                   
                 });
                 _database[remoteHost] = dbDetails;
                 
               },
               
              /**
               * Error, log the error
               */
              onError: () {
 
                log.severe("getProxyDetails HTTP fail, reason [${response.reasonPhrase}], code [${response.statusCode}]");
                
                
              });    
           
         });
    }
    
    return returnVal;
    
    
  }
    
  bool setProxyDetails(String remoteHost,
                      JsonObject details) {
      
    
  }
 
  bool removeProxyDetails(String remoteHost) {
      
    
  }
  

}
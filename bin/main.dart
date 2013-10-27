/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart'; 

import '../lib/deserati_proxy.dart';

void main() {
  
  /**
   * Initialise logging
   */
  DateTime now = new DateTime.now();
  String dateTime = now.toString();
  String logFileName = "$LOG_PATH$LOG_NAME-$dateTime.txt";
  Logger.root.onRecord.listen(new SyncFileLoggingHandler(logFileName));
  Logger log = new Logger('deserati_proxy');
  
  /**
   * Database
   */
  Map inMemoryDatabase = new Map<String,Map>(); 
  DpDatabase db = new DpDatabase(inMemoryDatabase);
  
  /**
   * Startup message
   */
  log.info('Deserati Proxy starting.....');
  DpProxyServer proxyServer = new DpProxyServer(HOST,
                                                PROXY_SERVER_PORT,
                                                db);
  
}


/*
 *       
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
    }*/

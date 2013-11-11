/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

import 'dart:async';

import 'package:logging/logging.dart' show Logger;
import 'package:logging_handlers/server_logging_handlers.dart' show SyncFileLoggingHandler; 

import '../lib/deserati_proxy.dart';

/**
 * The in memory database
 */
Map inMemoryDb = new Map<String,Map>();
DpDatabase db = new DpDatabase(COUCH_HOST,
                               DB_NAME,
                               inMemoryDb);

//TODO HttpClient changesClient = new HttpClient();

/**
 * Housekeeping processing
 */
void houseKeep (t) {
  
 /** 
  * Database changes
  */
 db.monitorChanges();

}

void main() {
  
  /**
   * Keep alive housekeeper
   */
  Duration keepAlive = new Duration(milliseconds: HOUSEKEEP_TIME);
  Timer keepAliveT = new Timer.periodic(keepAlive, houseKeep);
  
  /**
   * Initialise logging
   */
  DateTime now = new DateTime.now();
  String dateTime = now.toString();
  String logFileName = "$LOG_PATH$LOG_NAME-$dateTime.txt";
  Logger.root.onRecord.listen(new SyncFileLoggingHandler(logFileName));
  Logger log = new Logger('deserati_proxy');
  
  /**
   * Startup message
   */
  log.info('Deserati Proxy starting.....');
  
  /**
   * Database
   */
  log.info('Deserati Proxy Initialising Database.....');
  db.initialise();
 
  /**
   * Start the proxy server 
   */
  log.info('Deserati Starting Proxy Server.....');
  DpProxyServer proxyServer = new DpProxyServer(HOST,
      PROXY_SERVER_PORT,
      db);
  
  /**
   * Start the management server 
   */
  log.info('Deserati Starting Management Server.....');
  DpManagementServer managementServer = new DpManagementServer(HOST,
      MANAGEMENT_PORT,
      db);
 
  /**
   * Changes continuous feed test
   *TODO
 
  changesClient.getUrl(Uri.parse("http://$HOST/db/_changes?feed=continuous"))
    .then((request) => request.close())
      .then((response) => response.listen(print));  */
}




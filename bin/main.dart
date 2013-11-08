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

/**
 * Keep alive housekeeping processing
 */
int myTime = 0;

void stayAwake (t) {
  
 myTime++;
 
 /** 
  * Databse changes
  */
 if ( (myTime % DB_CHANGE_POLL) == 0) {
   
   db.monitorChanges();
   print("Updating DB");
 }
  
}

void main() {
  
  /**
   * Keep alive housekeeper
   */
  Duration keepAlive = new Duration(milliseconds: KEEP_ALIVE_TIME);
  Timer keepAliveT = new Timer.periodic(keepAlive, stayAwake);
  
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
  
}




/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 * 
 * Main function for the Dicerati proxy
 */

import 'dart:async';

import 'package:logging/logging.dart' show Logger;
import 'package:logging_handlers/server_logging_handlers.dart' show SyncFileLoggingHandler; 

import '../lib/dicerati_proxy.dart';

/**
 * The in memory database
 */
Map inMemoryDb = new Map<String,Map>();
DpDatabase db = new DpDatabase(COUCH_HOST,
                               DB_NAME,
                               inMemoryDb);

void main() {
  
  /**
   * Initialise logging
   */
  DateTime now = new DateTime.now();
  String dateTime = now.toString();
  String logFileName = "$LOG_PATH$LOG_NAME-$dateTime.txt";
  SyncFileLoggingHandler logFile = new SyncFileLoggingHandler(logFileName);
  Logger.root.onRecord.listen((r) => logFile.call(r));
  
  /**
   * Startup message
   */
  log.info('Dicerati Proxy starting.....');
  
  /**
   * Database, initialise then monitor for changes.
   */
  log.info('Dicerati Proxy Initialising Database.....');
  db.initialise();
  db.monitorChanges();
 
  /**
   * Start the management server 
   */
  log.info('Dicerati Starting Management Server.....');
  DpManagementServer managementServer = new DpManagementServer(HOST,
      MANAGEMENT_PORT,
      db);
  
  /**
   * Wrap the proxy server in a try block, if we fail here we need to restart.
   */
  try {
    
    /**
    * Start the proxy server 
    */
    log.info('Dicerati Starting Proxy Server.....');
    DpProxyServer proxyServer = new DpProxyServer(HOST,
        PROXY_SERVER_PORT,
        db);
  
    
  } catch(error,stacktrace) {
    
    /**
     * We need to fail here and allow system monitoring to re-start us,
     * saving what info we can.
     */
    log.severe("Dicerati Proxy Exception - terminating.", error, stacktrace);
    
  }
  
}

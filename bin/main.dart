/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
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
  Logger.root.onRecord.listen(new SyncFileLoggingHandler(logFileName));
  
  /**
   * Startup message
   */
  log.info('Dicerati Proxy starting.....');
  
  /**
   * Database
   */
  log.info('Dicerati Proxy Initialising Database.....');
  db.initialise();
  db.monitorChanges();
 
  /**
   * Start the proxy server 
   */
  log.info('Dicerati Starting Proxy Server.....');
  DpProxyServer proxyServer = new DpProxyServer(HOST,
      PROXY_SERVER_PORT,
      db);
  
  /**
   * Start the management server 
   */
  log.info('Dicerati Starting Management Server.....');
  DpManagementServer managementServer = new DpManagementServer(HOST,
      MANAGEMENT_PORT,
      db);
 
}

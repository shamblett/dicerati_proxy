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
  DpDatabase db = new DpDatabase(COUCH_HOST,
                                 DB_NAME);
  
  /**
   * Startup message
   */
  log.info('Deserati Proxy starting.....');
  DpProxyServer proxyServer = new DpProxyServer(HOST,
                                                PROXY_SERVER_PORT,
                                                db);
  
}

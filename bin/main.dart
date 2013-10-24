/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart'; 

import '../lib/deserati_proxy.dart';

final HOST = "127.0.0.1";
final SERVER_PORT = 8080;
final MANAGEMENT_PORT = 9001;


void main() {
  
  /**
   * Initialise logging
   */
  DateTime now = new DateTime.now();
  String dateTime = now.toString();
  String logFileName = "../logs/runlog-$dateTime.txt";
  Logger.root.onRecord.listen(new SyncFileLoggingHandler(logFileName));
  Logger log = new Logger('deserati_proxy');
  
  /**
   * Startup message
   */
  log.info('Deserati Proxy starting.....');
  TCPServer tcpserver = new TCPServer(HOST,SERVER_PORT);
}

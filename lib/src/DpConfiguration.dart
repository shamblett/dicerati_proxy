/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

/**
 * Servers
 */
final HOST = "141.196.22.207";
final PROXY_SERVER_PORT = 8080;
final MANAGEMENT_PORT = 9001;

/**
 * Logging
 */
final LOG_PATH = "../logs/";
final LOG_NAME = "runlog";

/**
 * Database
 */
final COUCH_HOST = '141.196.22.210';
final DB_NAME = 'deserati';

/**
 * HTML file paths, relative to main
 */ 
final MANAGEMENT_HOME = '../lib/src/html/management/index.html';
final ALERT = '../lib/src/html/management/alert.html';
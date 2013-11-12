/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of dicerati_proxy;

class DpException implements Exception {
  
  String _message = 'No Message Supplied';
  
  /**
   * Dp's exception class
   */
  DpException([this._message]);
  
  String toString() => "DpException: message = ${_message}";
}

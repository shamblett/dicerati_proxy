/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpManagement {
  
  /**
   * Command processing codes
   */
  static const  _HOST_IP_FAIL = 1;
  static const _PROXY_FAIL = 2;
  static const _PORT_FAIL = 3;
  static const  _SCHEME_FAIL = 4;
  static const _SUCCESS = 5;
  
  /**
   * Command processing parameters
   */
  final _urlValidator = '/^(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?\$/';
  final MIN_PORT = 0;
  final MAX_PORT = 65535;
  
  /**
   * Render the home page through mustache
   */
  String renderHTML(Map values) {
    
    String output;
    
    File homePage = new File(MANAGEMENT_HOME);
    String contents = homePage.readAsStringSync();
    var template = mustache.parse(contents, lenient:true);
    if ( values == null ) {
      
      output = template.renderString(null, lenient:true);
      
    } else {
      
      output = template.renderString(values, lenient:true);
    }
    
    return output;
    
  }
  
  /**
   * Check the incoming command parameters
   */
  bool checkUpdateParameters(Map parameters,
                             String alertBlock) {
    
    String alert;
    
    /**
     * We must always have a host ip
     */
    String hostIp = parameters['dp-host-ip'];
    /**
     * Check for a valid IPv4 adddress
     */
    try {
      
      Uri.parseIPv4Address(hostIp);
      
    } catch(e) {
      
      alert = getAlertBlock(_HOST_IP_FAIL);
      return false;
      
    }
    
    /**
     * Only check the others if not a remove command
     */
    if ( parameters['dpCommand'] != 'remove') {
   
      /**
      * Proxy Url 
      */
      String proxyUrl = parameters['dp-proxy-url'];
      if ( (proxyUrl == null) ||
           (proxyUrl.length == 0) ) {
      
        alert = getAlertBlock(_PROXY_FAIL);
        return false;
      
      }
    
      
      RegExp urlRegex = new RegExp(_urlValidator);
      if ( !urlRegex.hasMatch(proxyUrl)) {
        
        alert = getAlertBlock(_PROXY_FAIL);
        return false;
      }
      
      /**
       * Port
       */
      try {
      
       int port = parameters['dp-port'];
        
      } catch(e) {
        
        alert = getAlertBlock(_PORT_FAIL);
        return false;
        
      }
      int port = parameters['dp-port'];
      if ( port == null ) {
        
        alert = getAlertBlock(_PORT_FAIL);
        return false;
      
      }
      
      if ( (port < MIN_PORT) || 
           (port > MAX_PORT) ) {
      
        alert = getAlertBlock(_PORT_FAIL);
        return false;
      
      }
      
      /**
       * Scheme 
       */
      String scheme = parameters['scheme'];
      scheme.toLowerCase();
      if ( (scheme != 'http') ||
           (scheme != 'https') ) {
        
        alert = getAlertBlock(_SCHEME_FAIL);
        return false;
      }
      
    }
    
    alert = getAlertBlock(_SUCCESS);
    return true;
    
  }
  
  String getAlertBlock(int type) {
    
    String output;
    
    File alert = new File(ALERT);
    String alertContents = alert.readAsStringSync();
    var template = mustache.parse(alertContents, lenient:true);
    Map alertText = new Map();
    alertText['dp-alert-severity'] = 'alert-danger';
    
    switch ( type ) {
      
      case _HOST_IP_FAIL:
        
        alertText['dp-alert-text'] = 'Oops! The Host IP is invalid, please correct it.';
        break;
        
      case _PROXY_FAIL:
        
        alertText['dp-alert-text'] = 'Oops! The Proxy URL is invalid, please correct it.';
        break;
        
      case _PORT_FAIL:
        
        alertText['dp-alert-text'] = 'Oops! The Port number is invalid, please correct it.';
        break;
        
      case _SCHEME_FAIL:
        
        alertText['dp-alert-text'] = 'Oops! The Scheme is invalid, please correct it.';
        break;
        
      case _SUCCESS:
        
        alertText['dp-alert-text'] = 'OK, your update succeded.';
        alertText['dp-alert-severity'] = 'alert-success';
        break;
    }

    output = template.renderString(alertText, lenient:true);
    return output;
    
  }
  
  
}
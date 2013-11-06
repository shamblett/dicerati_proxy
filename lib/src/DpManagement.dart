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
    output = template.renderString(values, 
                                   lenient:true,
                                   htmlEscapeValues : false);
  
    return output;
    
  }
  
  /**
   * Check the incoming command parameters
   */
  String checkUpdateParameters(Map parameters ) {
    
    
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
      
      return getAlertBlock(_HOST_IP_FAIL);
      
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
      
        return getAlertBlock(_PROXY_FAIL);
      
      }
      
      /**
       * Port
       */
      try {
      
       int port = int.parse(parameters['dp-port']);
        
      } catch(e) {
        
        return getAlertBlock(_PORT_FAIL);
        
        
      }
      int port = int.parse(parameters['dp-port']);
      if ( port == null ) {
        
        return getAlertBlock(_PORT_FAIL);
      
      }
      
      if ( (port < MIN_PORT) || 
           (port > MAX_PORT) ) {
      
        return getAlertBlock(_PORT_FAIL);
      
      }
      
      /**
       * Scheme 
       */
      String scheme = parameters['dp-scheme'];
      scheme.toLowerCase().trim();
      if ( (scheme != 'http') &&
           (scheme != 'https') ) {
        
        return getAlertBlock(_SCHEME_FAIL);
        
      }
      
    }
    
    return null ;
    
  }
  
  String getAlertBlock(int type) {
    
    String output;
    
    File alert = new File(ALERT);
    String alertContents = alert.readAsStringSync();
    var template = mustache.parse(alertContents, 
                                  lenient:true);
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

    output = template.renderString(alertText, 
                                   lenient:true,
                                   htmlEscapeValues : false);
    return output;
    
  }
  
  
}
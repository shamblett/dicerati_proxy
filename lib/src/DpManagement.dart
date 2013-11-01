/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpManagement {
  
  final _HOST_IP_FAIL = 1;
  final _PROXY_FAIL = 2;
  final _PORT_FAIL = 3;
  final _SCHEME_FAIL = 4;
  final _urlValidator = '/^(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?\$/';
  final MIN_PORT = 0;
  final MAX_PORT = 65535;
  
  /**
   * Render the home page through mustache
   */
  String renderHTML(JsonObject values) {
    
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
      
      String alert = getAlertBlock(_HOST_IP_FAIL);
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
      
        String alert = getAlertBlock(_PROXY_FAIL);
        return false;
      
      }
    
      
      RegExp urlRegex = new RegExp(_urlValidator);
      if ( !urlRegex.hasMatch(proxyUrl)) {
        
        String alert = getAlertBlock(_PROXY_FAIL);
        return false;
      }
      
      /**
       * Port
       */
      try {
      
       int port = parameters['dp-port'];
        
      } catch(e) {
        
        String alert = getAlertBlock(_PORT_FAIL);
        return false;
        
      }
      int port = parameters['dp-port'];
      if ( port == null ) {
        
        String alert = getAlertBlock(_PORT_FAIL);
        return false;
      
      }
      
      if ( (port < MIN_PORT) || 
           (port > MAX_PORT) ) {
      
        String alert = getAlertBlock(_PORT_FAIL);
        return false;
      
      }
      
      /**
       * Scheme 
       */
      String scheme = parameters['scheme'];
      scheme.toLowerCase();
      if ( (scheme != 'http') ||
           (scheme != 'https') ) {
        
        String alert = getAlertBlock(_SCHEME_FAIL);
        return false;
      }
      
    }
    
    return true;
    
  }
  
  String getAlertBlock(int type) {
    
    
  }
  
}
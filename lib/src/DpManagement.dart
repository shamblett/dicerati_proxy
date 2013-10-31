/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpManagement {
  
  final HOST_IP_FAIL = 1;
  final PROXY_FAIL = 2;
  final PORT_FAIL = 3;
  final SCHEME_FAIL = 4;
  
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
      
      String alert = getAlertBlock(HOST_IP_FAIL);
      return false;
      
    }
    
    /**
     * Proxy Url must be valid
     */
    String proxyUrl = parameters['dp-proxy-url'];
    if ( (proxyUrl == null) ||
         (proxyUrl.length == 0) ) {
      
      String alert = getAlertBlock(PROXY_FAIL);
      return false;
      
    }
    
    
    
    return true;
    
  }
  
  String getAlertBlock(int type) {
    
    
  }
  
}
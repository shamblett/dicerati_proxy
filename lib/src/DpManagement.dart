/*
 * Package : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

class DpManagement {
  
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
  
}
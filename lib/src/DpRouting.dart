/*
 * Package : dicerati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of dicerati_proxy;


class DpRouting {
   
  /**
   * Resolve an incoming Uri to a file path
   */
  static String resolveUriPath(HttpRequest request) {
  
    List pathList = request.uri.pathSegments;
  
    switch ( pathList[0] ) {
    
      case 'images' :
      
        return IMAGES + pathList[1];
        break;
      
      default :
      
        return NO_PATH;
      
    }    
  
  }

}
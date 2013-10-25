/*
 * Packge : deserati_proxy
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 25/10/2013
 * Copyright :  S.Hamblett@OSCF
 */

part of deserati_proxy;

abstract class DpHTTPAdapter {
  
  
  DpHTTPAdapter();
  
  /*
   * Processes the HTTP request returning the server's response as
   * a JSON Object
   */
  void httpRequest(String method, 
                   String url, 
                   [String data = null,
                   Map headers = null]);
  
  /*
   * Result Handling
   */
  void onError(html.ProgressEvent response);
  void onSuccess(html.HttpRequest response);
  
}
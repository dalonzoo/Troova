import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';

import '../main.dart' as ContextUtility;
import '../mainScreens/SplashScreen.dart';

class UniServices{
  static String _code = '';
  static String get code => _code;
  static bool get hasCode => _code.isNotEmpty;


  static void reset(){
    _code = '';
  }

  static init()async{

    try{
      final appLinks = AppLinks();
      final Uri? uri = await appLinks.getInitialAppLink();
      uniHandler(uri);
    }on PlatformException {

      print("failed to receive the code");
    }

    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri? uri) async{
      uniHandler(uri);
    }, onError: (error){
      print(error);
    });
  }

  static uniHandler(Uri? uri){
    if(uri == null || uri.queryParameters.isEmpty){
        return;
      }

    Map<String,dynamic> param = uri.queryParameters;
    String receivedCode = param['code'] ?? '';
    Navigator.push(ContextUtility.navigatorKey.currentContext!,MaterialPageRoute(builder: (_) => SplashScreen()));
  }
}
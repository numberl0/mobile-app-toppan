import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class LoginModule {

  //Authentication
  Future<Map<String,dynamic>> validateLogin(Map<String, dynamic> data) async {
    Map<String,dynamic> responseMapping = {};
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.authPipe + "/auth");
    try {
      final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json',},
          body: jsonEncode(data),
        ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        var dataRes = responseDecode['data'];
        responseMapping = {
            'canLogin': true,
            'username': dataRes['username'],
            'token': dataRes['token'],
        };
      }else{
        print('Response Status Code: ${response.statusCode}');
        var responseDecode = jsonDecode(response.body);
         responseMapping = {
            'canLogin': false,
            'err': responseDecode['error']
        };
      }
    }catch (err) {
      throw err;
    }
    return responseMapping;
  }
  
}

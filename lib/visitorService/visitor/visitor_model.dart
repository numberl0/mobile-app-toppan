import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:path/path.dart' as path;

import '../../config/api_config.dart';

class VisitorformModule {

  UserEntity userEntity = UserEntity();

  Future<Map<String, dynamic>> getAgreementText() async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getAgreement');
    String token = await userEntity.getUserPerfer(userEntity.token);
    Map<String, dynamic> data = {};
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}',
          'Connection': 'keep-alive',
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        if(responseDecode['data'] != null){
          data = responseDecode['data'][0];
        }
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return data;
  }

  Future<List<dynamic>> getBuilding() async {
    final url = Uri.parse(
        ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getBuilding');
    String token = await userEntity.getUserPerfer(userEntity.token);
    List<dynamic> data = [];
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        if (responseDecode['data'] != null) {
          data = responseDecode['data'];
        }
      } else {
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return data;
  }


  Future<List<dynamic>> getManagerRole() async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getManagerRole');
    String token = await userEntity.getUserPerfer(userEntity.token);
    List<dynamic> data = [];
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        if(responseDecode['data'] != null){
          data = responseDecode['data'];
        }
      } else {
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return data;
  }

  Future<Map<String, dynamic>> getSequeceRunning(String type) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getSequenceRunning' + '?type=${Uri.encodeComponent(type)}');
    String token = await userEntity.getUserPerfer(userEntity.token);
    Map<String, dynamic> data = {};
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        if(responseDecode['data'] != null && responseDecode['data'].length == 1){
          data = responseDecode['data'][0];
        }
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return data;
  }

  // ---------------------------------------------- Update Table ---------------------------------------------- //
  // Check tno_pass doees not exist in Pass Request
  Future<bool?> passRequestDoesNotExist(String tno_pass) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/passRequestDoesNotExist' + '?tno_pass=${Uri.encodeComponent(tno_pass)}');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${token}',
          "Content-Type": "application/json",
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final data = jsonDecode(response.body);
        return data["doesNotExist"]; 
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
  }

  Future<void> updateSequeceRunning(String type, int sequence) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/updateSequenceRunning');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode({
          'type': type,
          'sequence': sequence
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print('Sequence found, status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
  }

  // Insert Pass Form
  Future<bool> uploadPassForm(Map<String, dynamic> data) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/uploadPassForm');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode(data),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print('Response body: ${response.body}');
        status = true;
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return status;
  }

  // Insert Pass Request
  Future<bool> uploadPassRequest(Map<String, dynamic> data) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/uploadPassRequest');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode(data),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print('Response body: ${response.body}');
        status = true;
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return status;
  }

  // ---------------------------------------------- Update Table ---------------------------------------------- //
  // Update Table Pass Form
  Future<bool> updatePassForm(Map<String, dynamic> data) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/updatePassForm');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode({
          'data': data,
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print('Response body: ${response.body}');
        status = true;
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return status;
  }

  // Update Table Request
  Future<bool> updatePassRequest(Map<String, dynamic> data) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/updatePassRequest');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode({
          'data': data,
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print('Response body: ${response.body}');
        status = true;
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return status;
  }

  // Upload Image Pass Request
  Future<bool> uploadImageFiles(String tno, String folderNameForm, Map<String, dynamic> data, String date) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/uploadImageFiles');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      var request = http.MultipartRequest('POST', url)..headers['Authorization'] = 'Bearer $token';;

      // Add other data fields if necessary (e.g., tno, type)
      request.fields['tno'] = tno;
      request.fields['date'] = date;
      request.fields['typeForm'] = folderNameForm;

      // Handle people signatures
      List<File?> peopleSignList = data['people'];
      for (int i = 0; i < peopleSignList.length; i++) {
        File? file = peopleSignList[i];
        if (file != null) {
          request.files.add(await http.MultipartFile.fromPath('people[]', file.path));
        }
      }

      // Handle item images (itemIn, itemOut, etc.) if available
      if (data['item_in'] != null) {
        List<File?> itemInImages = data['item_in'];
        for (int i = 0; i < itemInImages.length; i++) {
          File? file = itemInImages[i];
          if (file != null) {
            request.files.add(await http.MultipartFile.fromPath('item_in[]', file.path));
          }
        }
      }
      

      if (data['item_out'] != null) {
        List<File?> itemOutImages = data['item_out'];
        for (int i = 0; i < itemOutImages.length; i++) {
          File? file = itemOutImages[i];
          if (file != null) {
            request.files.add(await http.MultipartFile.fromPath('item_out[]', file.path));
          }
        }
      }

      if (data['approver'] != null) {
        List<File?> signImages = data['approver'];
        for (int i = 0; i < signImages.length; i++) {
          File? file = signImages[i];
          if (file != null) {
            request.files.add(await http.MultipartFile.fromPath('sign[]', file.path));
          }
        }
      }

      // Send the request
      var response = await request.send();
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print("Image uploaded successfully!");
        status = true;
      }else{
        print("Failed to upload image. Status code: ${response.statusCode}");
        var responseBody = await response.stream.bytesToString();
        print("Error message: $responseBody");
      }
    } catch (err, stackTrace) {
      String location = stackTrace.toString().split("\n").first;
      throw Exception("[ERROR] $err\n At line $location");
    }
    return status;
  }


  // Function Load image by url return Uint8List
  Future<Uint8List?> loadImageAsBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return response.bodyBytes;
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
  }



  // Function Load image by url return File
  Future<File?> loadImageToFile(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      final directory = await getTemporaryDirectory();

      // Extract filename from URL
      String fileName = path.basename(Uri.parse(imageUrl).path);
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
    }
  } catch (err) {
    throw err;
  }
}

}
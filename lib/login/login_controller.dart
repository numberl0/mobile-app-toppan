import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:toppan_app/loadingDialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';
import 'login_module.dart';

class LoginController {

  LoginModule loginModel = LoginModule();

  VisitorServiceCenterController _controllerVisistorServiceCenter = VisitorServiceCenterController();

  UserEntity userEntity = UserEntity();

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final LoadingDialog _loadingDialog = LoadingDialog();

  // Method to handle login
  Future<void> login(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      String username = usernameController.text;
      String password = passwordController.text;
      
      if(username.isNotEmpty && password.isNotEmpty){
        Map<String, dynamic> data_Req = {
          'username': username,
          'password': password
        };
        Map<String,dynamic> response = await loginModel.validateLogin(data_Req);
        if(response['canLogin']){
          final username = response['username'];
          final token = response['token'];
          await userEntity.setUserPerfer(userEntity.username, username);
          await userEntity.setUserPerfer(userEntity.token, token);

          //VisitorService
          bool loginSuccess = await visitorService();
          if(loginSuccess) {
            GoRouter.of(context).push('/home');
          }
        } else {
          _showErrorLoginDialog(context, response['err']);
        }
      } else {
        _showErrorLoginDialog(context, "กรุณากรอก username และ password");
      }
    } catch (err, stackTrace) {
      _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }


  //VisitorService
  Future<bool> visitorService() async {
    bool status = false;
    try {
      String username = await userEntity.getUserPerfer(userEntity.username);
      await _controllerVisistorServiceCenter.insertActvityLog('User ${username} login.');
      status = await _controllerVisistorServiceCenter.insertFCMToken();
    } catch (err, stackTrace) {
      _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return status;
  }




  void _showErrorLoginDialog(BuildContext context, String errMsg) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      headerAnimationLoop: false,
      title: 'เข้าสู่ระบบไม่สำเร็จ',
      titleTextStyle: TextStyle(fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold),
      desc: errMsg,
      descTextStyle: TextStyle(fontSize: 18, color: Colors.black,),
      btnOkOnPress: () {},
      btnOkIcon: Icons.cancel,
      btnOkColor: Colors.red.shade700,
    ).show();
  }



  Future<void> isTokenValid(BuildContext context) async {
    try{
      _loadingDialog.show(context);

      UserEntity userEntity = UserEntity();
      final token = await userEntity.getUserPerfer(userEntity.token);
      
      if (token != null && !JwtDecoder.isExpired(token)) {
        GoRouter.of(context).push('/home');
      }
    } catch (err, stackTrace) {
      _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 2));
      _loadingDialog.hide();
    }
  }

}

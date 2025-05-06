import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toppan_app/service_manager.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_model.dart';


import 'home_model.dart';

class HomeController {
  HomeModel _model = HomeModel();

  UserEntity userEntity = UserEntity();

  VisitorServiceCenterController _controllerVisistorServiceCenter = VisitorServiceCenterController();

  VisitorServiceCenterModel _visiorModel = VisitorServiceCenterModel();


  List<ServiceEntity> serviceList = [];
  Map<String, bool> servicesStatus = {};

  ServiceManager serviceManager = ServiceManager();

  Future<void> preparePage(BuildContext context) async {
    try {
      await checkConnectionService(context);
      var fcm_token = await userEntity.getUserPerfer(userEntity.fcm_token);

      if(fcm_token == null){
        //generate token FCM
        await userEntity.generateInfoDeviceToken();
         // List service want to insert FCM Token
        List<Future<bool>> serviceInsert = [
          _controllerVisistorServiceCenter.insertFCMToken(),
          // Other service have insert FCM
        ];
        
        List<bool> resultsInsert = await Future.wait(serviceInsert);
        bool servicesHaveFCMToken = resultsInsert.every((r) => r == true);
        if(!servicesHaveFCMToken) {
          GoRouter.of(context).push('/login');
          return;
        }
      }

      // List service #FIX
      List<Future<bool>> serviceCheck = [
        _controllerVisistorServiceCenter.checkFCMToken(),
      ];
      List<bool> resultsCheck = await Future.wait(serviceCheck);
      bool notHaveFCM = resultsCheck.every((r) => r == false);
      if(notHaveFCM){
        await userEntity.clearUserPerfer();
        GoRouter.of(context).push('/login');
        return;
      }
    } catch (err, stackTrace) {
      // _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<void> checkConnectionService(BuildContext context) async {
    Map<String, bool> servicesConnect = await _model.checkConnectionAllService();
    if(servicesConnect['visitor'] == true) {
      await prepareUserVisitor();
      await _controllerVisistorServiceCenter.updateActiveFCM();
    }

    servicesStatus = servicesConnect;


    serviceManager.preparePermissionsServices(servicesStatus);
    serviceList = await serviceManager.getAllService();
  }

  // Visitor Service
  Future<void> prepareUserVisitor() async {
    try {
      String username = await userEntity.getUserPerfer(userEntity.username);
      //VisitorService
      List<dynamic> roles = await _model.getRoleByUser(username);
      List<String> roleList = roles.cast<String>(); // dynamic to string
      await userEntity.setUserPerfer(userEntity.roles_visitorService, roleList);
    } catch (err, stackTrace) {
      await _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<bool> logout(BuildContext context) async {
    bool isLogout = false;
    try {
      await userEntity.clearUserPerfer();
      isLogout = true;
    } catch (err, stackTrace) {
      await _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return isLogout;
  }

}
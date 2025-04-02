import 'package:flutter/material.dart';
import 'package:toppan_app/service_manager.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';


import 'home_model.dart';

class HomeController {
  HomeModel _model = HomeModel();

  UserEntity userEntity = UserEntity();

  VisitorServiceCenterController _controllerVisistorServiceCenter = VisitorServiceCenterController();

  double screenWidth = 0;
  List<ServiceEntity> serviceList = [];
  Map<String, bool> servicesStatus = {};

  ServiceManager serviceManager = ServiceManager();

  Future<void> checkConnectionAllService(BuildContext context) async {
    Map<String, bool> servicesConnect = await _model.checkConnectionAllService();
    if(servicesConnect['visitor'] == true) {
      prepareUserVisitor();
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
      _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<bool> logout(BuildContext context) async {
    bool isLogout = false;
    try {
      String device_id = await userEntity.getUserPerfer(userEntity.device_id);
      await _model.deleteFCMToken(device_id);
      await userEntity.clearUserPerfer();
      isLogout = true;
    } catch (err, stackTrace) {
      _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return isLogout;
  }
}
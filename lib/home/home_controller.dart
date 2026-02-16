import 'package:flutter/material.dart';
import 'package:toppan_app/service_manager.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/center_controller.dart';


import 'home_model.dart';

class HomeController {
  HomeModel _model = HomeModel();

  UserEntity userEntity = UserEntity();

  CenterController _centerController = CenterController();

  ServiceManager serviceManager = ServiceManager();
  String displayName = '';
  bool hasNotification = true;

  /// ===== Prepare Home Page =====
  Future<void> preparePage(BuildContext context) async {
    try {
      // ===== AUTH CHECK (ศูนย์กลาง) =====
      final authenticated = await _centerController.ensureAuthenticated();
      if (!authenticated) {
        await _centerController.forceLogout(context);
        return;
      }

      // ===== USER INFO =====
      final rawName = await userEntity.getUserPerfer(userEntity.displayName);
      displayName = formatDisplayName(rawName);

      await prepareUser();

      // ===== FCM (ไม่เกี่ยวกับ auth) =====
      await _centerController.updateActiveFCM();

      // ===== PERMISSIONS / SERVICES =====
      await serviceManager.preparePermissionsServices();
    } catch (err, stackTrace) {
      await _centerController.logError(
        err.toString(),
        stackTrace.toString());
    }
  }

  Future<void> prepareUser() async {
    try {
      String username = await userEntity.getUserPerfer(userEntity.username);
      List<dynamic> roles = await _model.getRoleByUser(username);
      List<String> roleList = roles.cast<String>();
      await userEntity.setUserPerfer(userEntity.roles_visitorService, roleList);
      // hasNotification = await _model.hasNotification(username, roleList);
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<bool> logout(BuildContext context) async {
    try {
      await _centerController.forceLogout(context);
      return true;
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
      return false;
    }
  }

  String formatDisplayName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));

    // If the name has at least 3 parts, assume first is title
    if (parts.length >= 3) {
      final firstName = parts[1];
      final lastInitial = parts[2][0].toUpperCase();
      return '$firstName $lastInitial.';
    }

    // If only 2 parts, assume first name and last name
    if (parts.length == 2) {
      final firstName = parts[0];
      final lastInitial = parts[1][0].toUpperCase();
      return '$firstName $lastInitial.';
    }

    return parts.isNotEmpty ? parts[0] : fullName;
  }


}
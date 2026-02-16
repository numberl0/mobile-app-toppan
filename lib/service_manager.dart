import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toppan_app/home/home_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';

import 'userEntity.dart';


class ServiceManager {

  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();



  UserEntity userEntity = UserEntity();
  CenterController _controllerVisistorServiceCenter = CenterController();

  List<Map<String, dynamic>> taskServices = [];
  Map<String, dynamic> taskPermissions = {};



  Future<void> preparePermissionsServices() async {
    String username =  await userEntity.getUserPerfer(userEntity.username);
    List<String> roles =  await userEntity.getUserPerfer(userEntity.roles_visitorService);
    bool status = await HomeModel().hasNotification(username, roles);
    List<String> managerRoles = [
      'Manager',
      'CardManager',
      'Administrator',
      'SecurityManager'
    ];
    bool isAdmin = roles.any(managerRoles.contains);

    // --------------------------- Task Service --------------------------- //
     taskServices = [
    {'key': 'visitor', 'label': 'ผู้ติดต่อ', 'description': 'ใบผ่านบุคคลภายนอก', 'icon': Icons.person, 'enable': true, 'notify': false},
    {'key': 'employee', 'label': 'พนักงาน', 'description': 'ใบผ่านพนักงาน', 'icon': Icons.engineering, 'enable': true, 'notify': false},
    {'key': 'cardOff', 'label': 'ลืมบัตร', 'description': 'ใบคำร้องกรณีบัตรหาย/ชำรุด', 'icon': Icons.credit_card_off_outlined, 'enable': true, 'notify': false},
    {'key': 'search', 'label': 'ค้นหา', 'description': 'ค้นหาใบผ่านและใบคำร้อง', 'icon': Icons.content_paste_search, 'enable': true, 'notify': !isAdmin ? status : false},
    {'key': 'partTime', 'label': 'พาร์ทไทม์', 'description': 'พนักงานชั่วคราวและอื่นๆ', 'icon': Icons.transfer_within_a_station_rounded, 'enable': true, 'notify': false},
    {'key': 'approve', 'label': 'อนุมัติ', 'description': 'อนุมัติการเข้า/ออก', 'icon': Icons.fact_check_outlined, 'enable': true, 'notify': isAdmin ? status : false},
    {'key': 'logBook', 'label': 'ล็อกบุ๊ค', 'description': 'ล็อกบุ๊ค', 'icon': Icons.menu_book_rounded, 'enable': true, 'notify': false},
      // อื่นๆ...
    ];

    // --------------------------- Permission Task Service --------------------------- //
    taskPermissions = {
      'approve': managerRoles,
      'logBook': managerRoles,
      // อื่นๆ...
    };

    await filterTaskByPermissions();
    
  }

  Future<void> filterTaskByPermissions() async {
    // ดึง roles ของ user จาก storage / entity
    List<String> userRoles = await userEntity.getUserPerfer(userEntity.roles_visitorService) ?? [];

    for (var task in taskServices) {
      String taskKey = task['key'];
      
      // มีการกำหนด permission สำหรับ task นี้หรือไม่
      if (taskPermissions.containsKey(taskKey)) {
        List<String> allowedRoles = taskPermissions[taskKey] ?? [];

        // ถ้า user ไม่มี role ที่ match กับ allowedRoles ให้ปิด task
        bool hasPermission = userRoles.any((role) => allowedRoles.contains(role));
        if (!hasPermission) {
          task['enable'] = false;
        }
      }
    }
  }

  // Navigate to page
  void navigateToPage(BuildContext context, String selectedOption) {
      try {
        String route;
        switch (selectedOption) {
          case 'visitor':
            route = '/visitor?option=visitor';
            break;
          case 'employee':
            route = '/visitor?option=employee'; 
            break;
          case 'search':
            route = '/visitor?option=search';
            break;
          case 'approve':
            route = '/visitor?option=approve'; 
            break;
          case 'logBook':
            route = '/visitor?option=logBook'; 
            break;
          case 'cardOff':
            route = '/visitor?option=cardOff'; 
            break;
          case 'partTime':
            route = '/visitor?option=partTime'; 
            break;
          default:
            return;
        }
        GoRouter.of(context).push(route);
      } catch (err, stackTrace) {
        _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
      }
  }

}
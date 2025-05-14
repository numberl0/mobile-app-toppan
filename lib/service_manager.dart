import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';

import 'userEntity.dart';

class ServiceEntity {
  final String title;
  final bool enable;
  final String iconPath;
  final double iconWidth;
  final double iconHeight;
  final List<Color> backGroundColor;
  final Function(BuildContext)? onTap;

  ServiceEntity({
    required this.title,
    required this.enable,
    required this.iconPath,
    required this.iconWidth,
    required this.iconHeight, 
    required this.backGroundColor,
    required this.onTap,
  });
}

class ServiceManager {

  UserEntity userEntity = UserEntity();
  VisitorServiceCenterController _controllerVisistorServiceCenter = VisitorServiceCenterController();

  List<ServiceEntity> serviceList = [];
  Map<String, dynamic> taskServices = {};
  Map<String, dynamic> taskPermissions = {};

  Future<List<ServiceEntity>> getAllService() async {
    return serviceList;
  }

  void preparePermissionsServices(Map<String, bool> servicesStatus) async {
    // --------------------------- Task Service --------------------------- //
    taskServices = {
      'visitorService': 
      [
        {'key': 'visitor', 'label': 'ผู้ติดต่อ', 'icon': Icons.directions_walk_outlined, 'enable': true},
        {'key': 'employee', 'label': 'พนักงาน', 'icon': Icons.cases_rounded, 'enable': true},
        {'key': 'search', 'label': 'ค้นหา', 'icon': Icons.content_paste_search, 'enable': true},
        {'key': 'approve', 'label': 'อนุมัติ', 'icon': Icons.fact_check_outlined, 'enable': true},
      ],
      // other service task
    };

    // --------------------------- Permission Task Service --------------------------- //
    taskPermissions = {
      'visitorService': [
        {'key': 'approve', 'canOpen': ['Manager', 'CardManager', 'Administrator']},
      ],
      //other service task permission
    };

    filterTaskByPermissions();

    // --------------------------- All Service --------------------------- //
    serviceList = [
      // Visitor
      ServiceEntity(
        title: "Visitor",
        enable: servicesStatus['visitor']!,
        iconPath: 'assets/images/visitorService/icon_visitor.png',
        iconHeight: 150,
        iconWidth: 150,
        backGroundColor: [
                        Colors.blue.shade100,
                        Colors.blue.shade200,
                        Colors.blue.shade300,
                        Colors.blue.shade400,
                        Colors.blue.shade500
                      ],
        onTap: (context) {
          dialogServiceTask(context, taskServices['visitorService']);
        },
      ),
      // add other service
    ];
    
  }

  void filterTaskByPermissions() {
    taskServices.forEach((serviceKey, taskList) async {
      if (taskPermissions.containsKey(serviceKey)) {
        List<Map<String, dynamic>> permissionList = List<Map<String, dynamic>>.from(taskPermissions[serviceKey]);
        List<String> userRoles = await userEntity.getUserPerfer('roles_'+serviceKey);
        for (var task in taskList) {
          String taskKey = task['key'];

          var permissions = permissionList.firstWhere(
            (perm) => perm['key'] == taskKey,
            orElse: () => {},
          );

          if (permissions.isNotEmpty) {
            List<String> allowedRoles = List<String>.from(permissions['canOpen'] ?? []);

            bool hasPermission = userRoles.any((role) => allowedRoles.contains(role));
            if (!hasPermission) {
              task['enable'] = false;
            }
          }
        }
      }
    });
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
          default:
            return;
        }
        GoRouter.of(context).push(route);
      } catch (err, stackTrace) {
        _controllerVisistorServiceCenter.logError(err.toString(), stackTrace.toString());
      }
  }

  // Dialog Task Service
  void dialogServiceTask(BuildContext context, List<Map<String, dynamic>> serviceTask) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Service Tasks",
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final screenSize = MediaQuery.of(context).size;
        double dialogWidth = screenSize.width * 0.8;
        double dialogHeight = screenSize.height * 0.6;

        bool isTablet = screenSize.width > 799;
        int crossAxisCount = isTablet ? 3 : 2;
        double childAspectRatio = 1;
        
        double itemSize = isTablet ? 180 : 120;
        double iconSize = isTablet ? 60 : 40;
        double fontSize = isTablet ? 24 : 18;

        return FadeTransition(
          opacity: anim1,
          child: AlertDialog(
            backgroundColor:  Colors.white.withOpacity(0.8),
            contentPadding: EdgeInsets.all(0),
            content: Container(
              padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
              width: dialogWidth,
              height: dialogHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: serviceTask.where((task) => task['enable'] == true).length,
                      itemBuilder: (context, index) {
                        var enabledTasks = serviceTask.where((task) => task['enable'] == true).toList();
                        var item = enabledTasks[index];

                        return Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              navigateToPage(context, item['key']);
                            },
                            splashColor: Colors.blueAccent.withOpacity(0.3),
                            highlightColor: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(360),
                            child: Ink(
                              width: itemSize,
                              height: itemSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color.fromARGB(255, 0, 93, 199), Colors.blue.shade300],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item['icon'],
                                    size: iconSize + 10,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 6,
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    item['label'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: fontSize + 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(2, 2),
                                          blurRadius: 6,
                                          color: Colors.black.withOpacity(0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                parent: anim1,
                curve: Curves.easeOutQuart,
              ),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }

}
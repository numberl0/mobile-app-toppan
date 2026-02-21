import 'package:toppan_app/main.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/clear_temporary.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/home/home_controller.dart';
import 'package:toppan_app/service_manager.dart';

import '../component/CustomDIalog.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware, SingleTickerProviderStateMixin {
  static HomeController _controller = HomeController();
  static ServiceManager _controllerMenu = ServiceManager();
  Cleartemporary cleartemporary = Cleartemporary();

  bool _isLoading = true;
  double _fontSize = ApiConfig.fontSize; 
  bool isPhoneScale = false;

  AnimationController? _rotateController;
  Animation<double>? _rotation;

  @override
  void initState() {
    super.initState();
    reloadPage();

  if (_controller.hasNotification) {
      _rotateController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );

      _rotation = Tween<double>(
        begin: -0.02,
        end: 0.02,
      ).animate(
        CurvedAnimation(
          parent: _rotateController!,
          curve: Curves.easeInOut,
        ),
      );

      _rotateController?.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _rotateController?.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
  }

  @override
  void didPopNext() {
    reloadPage();
  }


  Future<void> preparePage() async {
    final success = await _controller.preparePage();
    if (!mounted) return;
    if (!success) {
      context.go('/login');
      return;
    }
    setState(() {
       _isLoading = false;
    });
  }

  Future<void> reloadPage() async {
    setState(() {
      _isLoading = true;
    });

    await cleartemporary.clearCache();
    await _controller.preparePage();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _fontSize = ApiConfig.getFontSize(context);
    isPhoneScale = ApiConfig.getPhoneScale(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.fromARGB(255, 132, 194, 252),
            Color.fromARGB(255, 45, 152, 240),
            Color.fromARGB(255, 48, 114, 236),
            Color.fromARGB(255, 0, 93, 199),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(
              flex: 25,
              child: buildDashboardHeader(),
            ),
            Expanded(
              flex: isPhoneScale ? 60:75,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(64),
                    topRight: Radius.circular(64),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: Offset(0, -2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(child: page(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardHeader() {
  return Container(
    width: double.infinity,
    margin: EdgeInsets.all(5),
    padding: EdgeInsets.all(0),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
  children: [
    Spacer(),
    PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'logout') {
          await CustomDialog.show(
            context: context,
            title: 'คำเตือน',
            message: 'คุณแน่ใจว่าต้องการออกจากระบบหรือไม่?',
            type: DialogType.info,
            onConfirm: () async {
              bool isLogout = await _controller.logout();
              if (isLogout) {
                showTopSnackBar(
                  Overlay.of(context),
                  CustomSnackBar.success(
                    backgroundColor: Colors.green.shade500,
                    icon: Icon(
                      Icons.sentiment_very_satisfied,
                      color: Colors.green.shade600,
                      size: 120,
                    ),
                    message: 'ออกจากระบบเรียบร้อย',
                  ),
                );
                GoRouter.of(context).go('/login');
              } else {
                showTopSnackBar(
                  Overlay.of(context),
                  CustomSnackBar.error(
                    backgroundColor: Colors.red.shade700,
                    icon: Icon(
                      Icons.sentiment_very_satisfied,
                      color: Colors.red.shade900,
                      size: 120,
                    ),
                    message: 'ออกจากระบบไม่สำเร็จ',
                  ),
                );
              }
            },
            onCancel: () => Navigator.pop(context),
          );
        }
      },

      child: Container(
        margin: EdgeInsets.only(right: 12),
        child: Chip(
          side: BorderSide.none,
          avatar: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Text(
              _controller.displayName.isNotEmpty
                  ? _controller.displayName.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          label: Text(
            _controller.displayName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey,
        ),
      ),

      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black),
              SizedBox(width: 8),
              Text('ออกจากระบบ'),
            ],
          ),
        ),
      ],
    ),
  ],
),







          Expanded(
  child: Padding(
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.05,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เมนูหลัก',
          style: TextStyle(
            color: Colors.white,
            fontSize: _fontSize + 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'เลือกหัวข้อที่ต้องการได้เลย!!',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: _fontSize,
          ),
        ),
      ],
    ),
  ),
),




        ],
      ),
    ),
  );
}

  Widget page(BuildContext context) {
  final ScrollController scrollController = ScrollController();
  double screenWidth = MediaQuery.of(context).size.width;
  double paddingHorizontal = screenWidth * 0.07;

  final List<Map<String, dynamic>> serviceTask = _controllerMenu.taskServices;
  final List<Map<String, dynamic>> enabledTasks = serviceTask.where((task) => task['enable'] == true).toList();

  int crossAxisCount = isPhoneScale ? 2 : 2;
  double iconSize = isPhoneScale ? 60 : 120;
  double fontSize = isPhoneScale ? 24 : 36 ;

  return Center(
    child: Container(
      
      padding: EdgeInsets.fromLTRB(paddingHorizontal, 16, paddingHorizontal, 16),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 40,
                mainAxisSpacing: 40,
                childAspectRatio: 1,
              ),
              itemCount: enabledTasks.length,
              itemBuilder: (context, index) {
  final item = enabledTasks[index];

  return InkWell(
    onTap: () {
      _controllerMenu.navigateToPage(context, item['key']);
    },
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        Positioned.fill(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFe3f2fd),
                  Color(0xFFbbdefb),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue, Colors.indigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Icon(
                    item['icon'],
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  item['label'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                if (!isPhoneScale) ...[
                  SizedBox(height: 6),
                  Text(
                    item['description'] ?? 'คำอธิบายของเมนูนี้',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize - 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

            if (item['notify'])
            Align(
              alignment: Alignment.topRight,
              child: Transform.translate(
                offset: const Offset(10, -10),
                child: RotationTransition(
                  turns: _rotation!,
                  child: Container(
                    width: isPhoneScale ? 36:50,
                    height: isPhoneScale ? 36:50,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: isPhoneScale ? 30:40,
                      ),
                    ),
                  ),
                ),
              ),
            ),


      ],
    ),
  );
}
            ),
          ),
        ),
      ),
    ),
  );
}

}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

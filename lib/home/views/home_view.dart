import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/clearTemporary.dart';
import 'package:toppan_app/home/controllers/home_controller.dart';
import 'package:toppan_app/service_manager.dart';


class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static HomeController _controller = HomeController();

  Cleartemporary cleartemporary = Cleartemporary();

  double _fontSize = 16.0;
  

  @override
  void initState() {
    super.initState();
    checkConnection();
    clearTemp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).size.width > 799) {
      setState(() {
        _controller.screenWidth = MediaQuery.of(context).size.width;
        _fontSize = 24.0;
      });
    }else{
      setState(() {
        _controller.screenWidth = MediaQuery.of(context).size.width;
        _fontSize = 16.0;
      });
    }
  }

  void clearTemp() async {
    await cleartemporary.listCacheFiles();
    print('-----------------');
    await cleartemporary.clearCache();
    print('-----------------');
    await cleartemporary.listCacheFiles();
  }

  void checkConnection() async {
    await _controller.checkConnectionAllService(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      )),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Menu',
            style: TextStyle(
                color: Colors.white,
                fontSize: _fontSize + 20,
                fontWeight: FontWeight.bold,
                shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 6,
                  color: Colors.black.withOpacity(0.8),
                ),
              ],
              ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                ],
                transform: GradientRotation(90),
              ),
            ),
          ),
          // actions: [
          //   IconButton(
          //     icon: Icon(
          //       Icons.notifications,
          //       color: Colors.white,
          //       size: 28,
          //     ),
          //     onPressed: () {},
          //   ),
          // ],
          leading: IconButton(
            icon: Icon(
              size: 40,
              Icons.logout,
              color: Colors
                  .white,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 6,
                  color: Colors.black.withOpacity(0.8),
                ),
              ],
            ),
            onPressed: () {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.info,
                buttonsBorderRadius: const BorderRadius.all(
                  Radius.circular(2),
                ),
                dismissOnTouchOutside: true,
                dismissOnBackKeyPress: false,
                headerAnimationLoop: false,
                animType: AnimType.bottomSlide,
                title: 'คำเตือน',
                titleTextStyle: TextStyle(
                    fontSize: _fontSize + 20, fontWeight: FontWeight.bold),
                desc: 'ต้องการออกจากระบบหรือไม่?',
                descTextStyle:
                    TextStyle(fontSize: _fontSize + 10, fontWeight: FontWeight.bold),
                showCloseIcon: true,
                // btnCancelColor: Colors.red.shade600,
                btnCancel: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Circular shape
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    elevation: 8, // Add elevation (shadow effect)
                    shadowColor: Colors.black.withOpacity(1), // Shadow color
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: _fontSize + 3,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                btnOk: ElevatedButton(
                  onPressed: () async {
                    bool isLogout = await _controller.logout(context);
                    if (isLogout) {
                      showTopSnackBar(
                        Overlay.of(context),
                        CustomSnackBar.success(
                          backgroundColor: Colors.green.shade500,
                          icon: Icon(Icons.sentiment_very_satisfied,
                              color: Colors.green.shade600, size: 120),
                          message: 'ออกจากระบบเรียบร้อย',
                        ),
                      );
                      GoRouter.of(context).go('/login');
                    } else {
                      showTopSnackBar(
                        Overlay.of(context),
                        CustomSnackBar.error(
                          backgroundColor: Colors.red.shade700,
                          icon: Icon(Icons.sentiment_very_satisfied,
                              color: Colors.red.shade900, size: 120),
                          message: 'ออกจากระบบไม่สำเร็จ',
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Circular shape
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    elevation: 8, // Add elevation (shadow effect)
                    shadowColor: Colors.black.withOpacity(1), // Shadow color
                  ),
                  child: Text(
                    'ยืนยัน',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: _fontSize + 3,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ).show();
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        body: page(context),
      ),
    );
  }

  Widget page(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Center(
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(16),
          child: _controller.serviceList.length == 1
              ? Center(child: buildService(context, _controller.serviceList[0]))
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                    scrollbars: false,
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Center( // Ensures GridView is centered
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.95),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.maxWidth > 799 ? 3 : 2,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _controller.serviceList.length,
                          itemBuilder: (context, index) {
                            return buildService(context, _controller.serviceList[index]);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    ),
  );
  }

  Widget buildService(BuildContext context, ServiceEntity data) {
    int imageLengthControl = 2;
    if(MediaQuery.of(context).size.width > 799 || _controller.servicesStatus.length <= 2) {
        imageLengthControl = 1;
    }
    return Stack(
      children: [
        InkWell(
          onTap: data.enable == false
              ? () {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.warning,
                    headerAnimationLoop: false,
                    animType: AnimType.topSlide,
                    showCloseIcon: true,
                    title: 'แจ้งเตือน',
                    titleTextStyle: TextStyle(
                      fontSize: _fontSize + 30,
                      fontWeight: FontWeight.bold,
                    ),
                    desc:
                        'ระบบ ${data.title} ไม่สามารถให้บริการได้ในตอนนี้ ขออภัยในความไม่สะดวก',
                    descTextStyle: TextStyle(
                      fontSize: _fontSize + 10,
                      fontWeight: FontWeight.bold,
                    ),
                    btnOk: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(1),
                      ),
                      child: Text(
                        'ยืนยัน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _fontSize + 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).show();
                }
              : () {
                  data.onTap!(context);
                },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 300,
            width: 275,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: data.enable == false
                    ? [Colors.grey.shade300, Colors.grey.shade500]
                    : data.backGroundColor,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  data.iconPath,
                  width: data.iconWidth / imageLengthControl,
                  height: data.iconHeight / imageLengthControl,
                ),
                SizedBox(height: 15),
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: _fontSize + 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (data.enable == false)
          Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade600,
              size: 40,
            ),
          ),
      ],
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

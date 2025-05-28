import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:device_preview/device_preview.dart';
import 'package:toppan_app/config/api_config.dart';


import 'firebase/firebase_message.dart';
import 'login/login_view.dart';
import 'home/home_view.dart';
import 'visitorService/visitorServiceCenter_view.dart';

import 'package:responsive_framework/responsive_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessage firebaseMessage = FirebaseMessage();
  await firebaseMessage.initNotifications();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    DevicePreview(
      enabled: false,    // <--- Preview UI
      builder: (context) => MyApp(),
    ),
  );
}

final GoRouter _router =  GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) => HomePage(),
    ),
    GoRoute(
      path: '/visitor',
      builder: (BuildContext context, GoRouterState state) {
        final String? selectedOption = state.uri.queryParameters['option'];
        final Map<String, dynamic>? dataDoc = state.extra as Map<String, dynamic>?;
        return VisitorPage(
          selectedOption: selectedOption ?? 'Unknown',
          documentData: dataDoc,
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        fontFamily: 'NotoSans',
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) => ResponsiveBreakpoints(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 600, name: MOBILE),
          const Breakpoint(start: 601, end: 1300, name: TABLET),
          const Breakpoint(start: 1301, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ]
      ),
    );
  }
}
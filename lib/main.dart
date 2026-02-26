import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:device_preview/device_preview.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/splash_page.dart';
import 'package:toppan_app/userEntity.dart';


import 'firebase/firebase_message.dart';
import 'login/login_view.dart';
import 'home/home_view.dart';
import 'visitorService/approve/approve_view.dart';
import 'visitorService/permission/permis_view.dart';

import 'package:responsive_framework/responsive_framework.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'visitorService/employee/employee_view.dart';
import 'visitorService/logBook/logBook_view.dart';
import 'visitorService/partTime/partTime_view.dart';
import 'visitorService/search/search_view.dart';
import 'visitorService/visitor/visitor_view.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessage firebaseMessage = FirebaseMessage();
  await firebaseMessage.initNotifications();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  AppDateTime.initialize();
  runApp(
  kReleaseMode
      ? MyApp()
      : DevicePreview(
          enabled: true,    // <--- Preview UI
          builder: (context) => MyApp(),
        ),
);
}

// Global Router
final GoRouter appRouter =  GoRouter(
  initialLocation: '/splash',
  observers: [routeObserver],
  /// 🔥 Global redirect protection
    redirect: (context, state) async {
      final token = await UserEntity().getAccessToken();

      final loggingIn = state.matchedLocation == '/login';

      if (token == null && !loggingIn) {
        return '/login';
      }

      if (token != null && loggingIn) {
        return '/home';
      }

      return null;
    },
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),

    GoRoute(
      path: '/visitor',
      builder: (context, state) => VisitorPage(
        documentData: state.extra as Map<String, dynamic>?,
      ),
    ),

    GoRoute(
      path: '/employee',
      builder: (context, state) => EmployeePage(
        documentData: state.extra as Map<String, dynamic>?,
      ),
    ),

    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),

    GoRoute(
      path: '/approve',
      builder: (context, state) => const ApprovePage(),
    ),

    GoRoute(
      path: '/logBook',
      builder: (context, state) => const LogBookPage(),
    ),

    GoRoute(
      path: '/permis',
      builder: (context, state) => PermisPage(
        documentData: state.extra as Map<String, dynamic>?,
      ),
    ),

    GoRoute(
      path: '/partTime',
      builder: (context, state) => const PartTimePage(),
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

      locale: const Locale('th', 'TH'),
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: appRouter,
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
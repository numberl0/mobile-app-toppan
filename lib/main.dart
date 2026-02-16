import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:device_preview/device_preview.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/splash_page.dart';


import 'firebase/firebase_message.dart';
import 'login/login_view.dart';
import 'home/home_view.dart';
import 'visitorService/center_view.dart';

import 'package:responsive_framework/responsive_framework.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

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
    DevicePreview(
      enabled: true,    // <--- Preview UI
      builder: (context) => MyApp(),
    ),
  );
}

final GoRouter _router =  GoRouter(
  initialLocation: '/splash',
  observers: [routeObserver],
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
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
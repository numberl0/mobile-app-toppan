import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toppan_app/userEntity.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<StatefulWidget> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  UserEntity userEntity = UserEntity();

  @override
  void initState() {
    super.initState();
    // _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    // หน่วงนิดหน่อย กันจอวูบ + ให้ storage พร้อม
    await Future.delayed(const Duration(milliseconds: 500));

    final refreshToken = await userEntity.getRefreshToken();

    if (!mounted) return;

    if (refreshToken != null && refreshToken.toString().isNotEmpty) {
      // เคย login แล้ว → เข้า Home เลย
      GoRouter.of(context).go('/home');
    } else {
      // ไม่เคย login
      GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
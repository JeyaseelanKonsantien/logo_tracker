import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _o = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _o = 1));
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: AnimatedOpacity(
        opacity: _o,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeIn,
        child: Image.asset(
          'assets/images/logo.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain, // FIX: Changed from Alignment.center to BoxFit.contain
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
                Icons.business,
                size: 100,
                color: Colors.red
            );
          },
        ),
      ),
    ),
  );

}

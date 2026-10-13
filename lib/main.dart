import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'state/settings_store.dart';
import 'ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsStore.instance.load();
  await WakelockPlus.enable(); // screen never turns off while the app is open
  runApp(const LogoTrackerApp());
}

class LogoTrackerApp extends StatelessWidget {
  const LogoTrackerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Logo Tracker',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const SplashScreen(),
  );
}
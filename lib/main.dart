import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'state/settings_store.dart';
import 'ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red).copyWith(
        primary: Colors.red,
        onPrimary: Colors.white,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.red,
        thumbColor: Colors.red,
        inactiveTrackColor: Colors.white24,
        overlayColor: Color(0x33FF0000),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: Colors.red),
      ),
    ),
    home: const SplashScreen(),
  );
}
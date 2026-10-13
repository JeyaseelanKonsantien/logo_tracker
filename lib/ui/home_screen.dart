import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'tracking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    void go(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                    Icons.business,
                    size: 80,
                    color: Colors.red // CHANGED: Brandix Red Fallback
                );
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: () => go(const TrackingScreen()),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Tracking'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red, // CHANGED: Active Brandix color
                  )),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                  onPressed: () => go(const SettingsScreen()),
                  icon: const Icon(Icons.settings, color: Colors.red), // CHANGED: Icon color
                  label: const Text('Advanced Settings', style: TextStyle(color: Colors.red)), // CHANGED: Text color
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red), // CHANGED: Border border color
                  )),
            ),
            const Spacer(),
          ]),
        ),
      ),
    );
  }
}

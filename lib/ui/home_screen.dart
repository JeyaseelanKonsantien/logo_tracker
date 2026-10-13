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
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(children: [
                  const SizedBox(height: 24),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.business, size: 80, color: Colors.red),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => go(const TrackingScreen()),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Tracking'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => go(const SettingsScreen()),
                      icon: const Icon(Icons.settings, color: Colors.red),
                      label: const Text('Advanced Settings',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const Spacer(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../state/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _c = TextEditingController(text: SettingsStore.instance.endpoint);
  final _key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Advanced Settings')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _key,
            child: Column(children: [
              TextFormField(
                controller: _c,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'IP Path',
                  helperText:
                      'http://192.168.1.100:8080/signal  or  tcp://192.168.1.100:5000',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => SettingsStore.isValid(v ?? '')
                    ? null
                    : 'Enter a valid URL / IP / tcp:// path',
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red, // Change this to your preferred color
                  foregroundColor: Colors.white, // Color of the text inside
                ),
                onPressed: () async {
                  if (!_key.currentState!.validate()) return;
                  await SettingsStore.instance.save(_c.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Saved')));
                  }
                },
                child: const Text('Save'),
              )

            ]),
          ),
        ),
      );
}

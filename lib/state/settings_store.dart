import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore._();
  static final instance = SettingsStore._();
  String endpoint = 'http://192.168.1.100:8080/signal';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    endpoint = p.getString('endpoint') ?? endpoint;
  }

  Future<void> save(String v) async {
    endpoint = v;
    (await SharedPreferences.getInstance()).setString('endpoint', v);
  }

  static bool isValid(String s) {
    s = s.trim();
    final ip = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d{1,5})?(/.*)?$');
    if (ip.hasMatch(s)) return true;
    final u = Uri.tryParse(s);
    if (u == null || u.host.isEmpty) return false;
    if (u.scheme == 'tcp') return u.hasPort;
    return u.scheme == 'http' || u.scheme == 'https';
  }
}

import 'dart:async';
import 'dart:io';

class SignalSender {
  SignalSender(String endpoint) {
    var e = endpoint.trim();
    if (!e.contains('://')) e = 'http://$e';
    _uri = Uri.parse(e);
    _http.connectionTimeout = const Duration(seconds: 1);
  }
  late final Uri _uri;
  final _http = HttpClient();
  Socket? _sock;
  bool _busy = false;
  int? _pending;

  Future<void> send(int value) async {
    _pending = value;
    if (_busy) return;
    _busy = true;
    while (_pending != null) {
      final v = _pending!;
      _pending = null;
      try {
        _uri.scheme == 'tcp' ? await _tcp(v) : await _post(v);
      } catch (_) {
        _sock?.destroy();
        _sock = null;
      }
    }
    _busy = false;
  }

  Future<void> _post(int v) async {
    final r = await _http.postUrl(_uri);
    r.headers.contentType = ContentType.text;
    r.write('$v');
    final res = await r.close();
    await res.drain();
  }

  Future<void> _tcp(int v) async {
    _sock ??= await Socket.connect(_uri.host, _uri.port,
        timeout: const Duration(seconds: 1));
    _sock!.setOption(SocketOption.tcpNoDelay, true);
    _sock!.write('$v\n');
    await _sock!.flush();
  }

  void dispose() {
    _http.close(force: true);
    _sock?.destroy();
  }
}

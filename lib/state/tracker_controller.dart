import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/signal_sender.dart';
import '../vision/vision_worker.dart';
import 'settings_store.dart';

class TrackerController extends ChangeNotifier {
  CameraController? cam;
  Isolate? _iso;
  SendPort? _worker;
  final _rx = ReceivePort();
  late final SignalSender _sender;
  Timer? _heartbeat;
  bool _busy = false;
  List<double>? _learnRequest;

  // UI-visible state (coordinates normalised 0..1 of the preview).
  Rect roi = const Rect.fromLTWH(0.40, 0.35, 0.20, 0.30);
  double gateCenter = 0.5;
  double gateWidth = 0.04; // calibrate so this span == 0.5 mm on the belt
  Offset? center;
  double score = 0;
  bool learned = false;
  bool editing = true; // true = selection box visible   <-- ADDED
  int signal = 0;
  String? error;

  double get gateL => gateCenter - gateWidth / 2;
  double get gateR => gateCenter + gateWidth / 2;

  Future<void> init() async {
    try {
      _sender = SignalSender(SettingsStore.instance.endpoint);
      _rx.listen(_onMsg);
      _iso = await Isolate.spawn(visionEntry, _rx.sendPort);
      final cams = await availableCameras();
      cam = CameraController(cams.first, ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
              ? ImageFormatGroup.yuv420
              : ImageFormatGroup.bgra8888);
      await cam!.initialize();
      await cam!.lockCaptureOrientation(DeviceOrientation.landscapeLeft);

      await Future.delayed(const Duration(milliseconds: 1000));
      try {
        await cam!.setFocusMode(FocusMode.locked);
      } catch (_) {
      }
      await cam!.startImageStream(_onFrame);
      // Re-assert current state so the endpoint always sees a fresh value.
      _heartbeat = Timer.periodic(
          const Duration(milliseconds: 200), (_) => _sender.send(signal));
    } catch (e) {
      error = '$e';
    }
    notifyListeners();
  }

  void _onFrame(CameraImage f) {
    if (_busy || _worker == null) return; // drop frames, never queue
    _busy = true;
    final p = f.planes.first; // Y plane (Android) or BGRA (iOS)
    final bpp = f.planes.length == 1 ? 4 : 1;
    final req = _learnRequest;
    _learnRequest = null;
    _worker!.send([
      'frame',
      TransferableTypedData.fromList([Uint8List.fromList(p.bytes)]),
      f.width, f.height, p.bytesPerRow, bpp, req
    ]);
  }

  void _onMsg(dynamic m) {
    switch (m[0]) {
      case 'ready':
        _worker = m[1];
      case 'learned':
        learned = true;
        editing = false; // hide the box once the logo is learned
        notifyListeners();
      case 'result':
        _busy = false;
        final found = m[1] as bool;
        center = found ? Offset(m[2], m[3]) : null;
        score = m[4];
        final inGate = found && center!.dx >= gateL && center!.dx <= gateR;
        final next = inGate ? 1 : 0;
        if (next != signal) {
          signal = next;
          _sender.send(signal); // immediate on change
        }
        notifyListeners();
    }
  }

  void learnTemplate() =>
      _learnRequest = [roi.left, roi.top, roi.right, roi.bottom];


  void startRelearn() {
    editing = true;
    notifyListeners();
  }

  void setRoi(Rect r) {
    roi = Rect.fromLTRB(r.left.clamp(0.0, 0.95), r.top.clamp(0.0, 0.95),
        r.right.clamp(0.05, 1.0), r.bottom.clamp(0.05, 1.0));
    notifyListeners();
  }

  void setGate({double? c, double? w}) {
    gateCenter = c ?? gateCenter;
    gateWidth = w ?? gateWidth;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _sender.send(0);
    cam?.stopImageStream().catchError((_) {});
    cam?.dispose();
    _iso?.kill(priority: Isolate.immediate);
    _rx.close();
    super.dispose();
  }
}
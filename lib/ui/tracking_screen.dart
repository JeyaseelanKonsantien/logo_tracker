import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/tracker_controller.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final t = TrackerController();
  bool _resize = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    t.init();
  }

  @override
  void dispose() {
    t.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: ListenableBuilder(
        listenable: t,
        builder: (_, __) {
          if (t.error != null) {
            return Center(
                child: Text(t.error!,
                    style: const TextStyle(color: Colors.red)));
          }
          if (t.cam == null || !t.cam!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Row(children: [
            Expanded(
                child: Center(
                    child: AspectRatio(
                        aspectRatio: t.cam!.value.aspectRatio,
                        child: _view()))),
            SizedBox(width: 220, child: _panel()),
          ]);
        },
      ),
    ),
  );

  Widget _view() => LayoutBuilder(builder: (_, c) {
    final w = c.maxWidth, h = c.maxHeight;
    return GestureDetector(
      onPanStart: (d) {
        if (!t.editing) return;
        final p = Offset(d.localPosition.dx / w, d.localPosition.dy / h);
        _resize = (p - t.roi.bottomRight).distance < 0.06;
      },
      onPanUpdate: (d) {
        if (!t.editing) return;
        final r = t.roi;
        final dx = d.delta.dx / w, dy = d.delta.dy / h;
        if (_resize) {
          t.setRoi(Rect.fromLTRB(r.left, r.top, r.right + dx, r.bottom + dy));
        } else {
          final s = r.shift(Offset(dx, dy));
          if (s.left >= 0 && s.top >= 0 && s.right <= 1 && s.bottom <= 1) {
            t.setRoi(s);
          }
        }
      },
      child: Stack(fit: StackFit.expand, children: [
        CameraPreview(t.cam!),
        CustomPaint(painter: _Overlay(t)),
      ]),
    );
  });

  Widget _panel() => Container(
    color: Colors.grey.shade900,
    padding: const EdgeInsets.all(10),
    child: SingleChildScrollView(
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            color: t.signal == 1 ? Colors.green : Colors.red.shade800,
            child: Text('SIGNAL ${t.signal}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(t.center == null
              ? 'No logo  (score ${t.score.toStringAsFixed(2)})'
              : 'x ${t.center!.dx.toStringAsFixed(3)}  y ${t.center!.dy.toStringAsFixed(3)}\nscore ${t.score.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: t.editing ? t.learnTemplate : t.startRelearn,
              child: Text(t.editing ? 'Learn logo' : 'Re-learn logo')),
          const SizedBox(height: 8),
          const Text('Gate position'),
          Slider(value: t.gateCenter, min: 0.05, max: 0.95, onChanged: (v) => t.setGate(c: v)),
          const Text('Gate width (= 0.5 mm)'),
          Slider(value: t.gateWidth, min: 0.005, max: 0.2, onChanged: (v) => t.setGate(w: v)),

          // ---- NEW: match score slider ----
          Text('Match score: ${t.threshold.toStringAsFixed(2)}'),
          Slider(
              value: t.threshold,
              min: 0.30,
              max: 0.95,
              onChanged: t.setThreshold),
          // ---------------------------------

          const Text('Drag box to move;\ndrag corner dot to resize.',
              style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
    ),
  );
}

class _Overlay extends CustomPainter {
  _Overlay(this.t) : super(repaint: t);
  final TrackerController t;
  @override
  void paint(Canvas c, Size s) {
    if (t.editing) _paintBox(c, s);
    _paintRest(c, s);
  }

  void _paintBox(Canvas c, Size s) {
    final r = t.roi;
    final px = Rect.fromLTRB(r.left * s.width, r.top * s.height, r.right * s.width, r.bottom * s.height);
    c.drawRect(px, Paint()..color = Colors.amber..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(px.bottomRight, 8, Paint()..color = Colors.amber);
  }

  void _paintRest(Canvas c, Size s) {
    final gate = Paint()
      ..color = t.signal == 1 ? Colors.greenAccent : Colors.cyan
      ..strokeWidth = 2;
    for (final x in [t.gateL, t.gateR]) {
      c.drawLine(Offset(x * s.width, 0), Offset(x * s.width, s.height), gate);
    }
    if (t.center != null) {
      final p = Offset(t.center!.dx * s.width, t.center!.dy * s.height);
      final m = Paint()..color = Colors.redAccent..strokeWidth = 2;
      c.drawLine(p - const Offset(12, 0), p + const Offset(12, 0), m);
      c.drawLine(p - const Offset(0, 12), p + const Offset(0, 12), m);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

import 'dart:isolate';
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;


const _procWidth = 320; // frames are downscaled to this width for speed
const matchThreshold = 0.55;

void visionEntry(SendPort main) {
  final port = ReceivePort();
  main.send(['ready', port.sendPort]);
  cv.Mat? tmpl;

  // Gray -> downscale -> histogram equalisation -> light blur (low-contrast robustness).
  cv.Mat prep(List m) {
    final bytes = (m[1] as TransferableTypedData).materialize().asUint8List();
    final w = m[2] as int, h = m[3] as int, stride = m[4] as int, bpp = m[5] as int;
    final raw = cv.Mat.fromList(h, stride ~/ bpp,
        bpp == 1 ? cv.MatType.CV_8UC1 : cv.MatType.CV_8UC4, bytes);
    final gray = bpp == 1 ? raw : cv.cvtColor(raw, cv.COLOR_BGRA2GRAY);
    final roi = gray.region(cv.Rect(0, 0, w, h));
    final s = _procWidth / w;
    final small = cv.resize(roi, ((w * s).round(), (h * s).round()));
    final eq = cv.equalizeHist(small);
    final out = cv.gaussianBlur(eq, (3, 3), 0);
    for (final x in [raw, if (bpp != 1) gray, roi, small, eq]) {
      x.dispose();
    }
    return out;
  }

  port.listen((m) {
    if (m is! List || m[0] != 'frame') return;
    final img = prep(m);
    final learn = m[6] as List?;
    if (learn != null) {
      final x = ((learn[0] as double) * img.cols).round().clamp(0, img.cols - 9);
      final y = ((learn[1] as double) * img.rows).round().clamp(0, img.rows - 9);
      final w = (((learn[2] as double) - learn[0]) * img.cols).round().clamp(8, img.cols - x);
      final h = (((learn[3] as double) - learn[1]) * img.rows).round().clamp(8, img.rows - y);
      tmpl?.dispose();
      tmpl = img.region(cv.Rect(x, y, w, h)).clone();
      main.send(['learned', true]);
    }
    final t = tmpl;
    if (t == null || t.cols >= img.cols || t.rows >= img.rows) {
      img.dispose();
      main.send(['result', false, 0.0, 0.0, 0.0]);
      return;
    }
    final res = cv.matchTemplate(img, t, cv.TM_CCOEFF_NORMED);
    final (_, maxVal, _, maxLoc) = cv.minMaxLoc(res);
    // Exact centre of the matched logo, normalised to 0..1.
    final cx = (maxLoc.x + t.cols / 2) / img.cols;
    final cy = (maxLoc.y + t.rows / 2) / img.rows;
    res.dispose();
    img.dispose();
    main.send(['result', maxVal >= matchThreshold, cx, cy, maxVal]);
  });
}

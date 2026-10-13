# Logo Tracker

A Flutter app that watches a conveyor belt through the phone camera, learns a logo from a user-drawn box, tracks the logo's center point in real time, and sends a `1` / `0` signal to a network endpoint when the logo passes through a virtual gate.

Built with Flutter, [`camera`](https://pub.dev/packages/camera) and [OpenCV for Dart](https://pub.dev/packages/opencv_dart).

<!-- Add screenshots here
![Home](docs/home.png) ![Tracking](docs/tracking.png)
-->

## Features

- **Splash and Home screens** with company logo, fade-in animation and 2.5 s auto-transition.
- **Advanced Settings** with a validated endpoint field (HTTP URL, bare IP or `tcp://host:port`), saved on the device.
- **Live camera preview** with a draggable, resizable selection box.
- **Template learning:** the pixels inside the box become the reference template. The box hides after learning and comes back with **Re-learn logo**.
- **Low-contrast robustness:** grayscale, downscaling, histogram equalization and light blur before matching, so faint or embroidered logos still match.
- **Virtual gate:** two vertical lines whose position and spacing are adjustable (calibrate the gap to 0.5 mm on your belt).
- **Center-point tracking** of the logo on every processed frame.
- **Low-latency signalling:** a `1` or `0` is sent the moment the state changes, and the current value is re-sent every 200 ms.
- **Isolate-based processing:** image analysis runs on a separate isolate so the UI stays smooth. Frames are dropped, never queued, when the worker is busy.
- **Screen stays on** while the app runs, and **autofocus is locked** after the first second.

## How it works

```
Camera stream ──► Isolate (OpenCV) ──► center (x, y) + score
                                            │
                       center.x between gate lines?
                                            │
                         yes → "1"        no → "0"
                                            │
                            HTTP POST  or  TCP socket
```

1. The camera delivers frames (Y plane on Android, BGRA on iOS).
2. The worker converts to grayscale, resizes to 320 px wide, equalizes the histogram and blurs slightly.
3. `matchTemplate` (normalized correlation) finds the best match. A score of **0.55 or higher** counts as "logo found".
4. The match center is normalized to `0..1` and compared with the two gate lines.
5. The signal is `1` while the center is between or on the gate lines, and `0` otherwise, including when no logo is found.

## Project structure

```
lib/
├─ main.dart                      App entry, wakelock, settings load
├─ ui/
│  ├─ splash_screen.dart          Logo fade-in, then Home
│  ├─ home_screen.dart            Start Tracking / Advanced Settings
│  ├─ settings_screen.dart        Endpoint editor with validation
│  └─ tracking_screen.dart        Preview, selection box, gate overlay, controls
├─ state/
│  ├─ tracker_controller.dart     Camera, isolate, gate logic, signalling
│  └─ settings_store.dart         Persisted endpoint + validation
├─ services/
│  └─ signal_sender.dart          HTTP POST / TCP sender
└─ vision/
   └─ vision_worker.dart          Isolate: preprocessing + template matching
assets/images/logo.png            Your company logo
```

## Getting started

### Requirements

- Flutter SDK 3.19 or newer (Dart 3.3+)
- A physical Android or iOS device (the camera is not available on most emulators)

### Install

```bash
git clone <your-repo-url>
cd logo_tracker
flutter create .        # only if android/ and ios/ folders are missing
flutter pub get
```

### Add your logo

Place the file at `assets/images/logo.png`. It is already registered in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/logo.png
```

Assets are bundled at build time, so run `flutter clean` and rebuild after adding or changing it.

### Platform setup

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>

<application
    android:usesCleartextTraffic="true"  ...>
```

Set `minSdkVersion` to at least `24` in `android/app/build.gradle` (check the `opencv_dart` and `camera` docs for current requirements).

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used to track logos on the conveyor belt.</string>
```

### Run

```bash
flutter run --release
```

Use release mode for real tests. Debug mode is much slower and will distort latency.

## Usage

1. Open **Advanced Settings**, enter the endpoint and tap **Save**.
2. Tap **Start Tracking** and point the phone at the belt. Focus locks after about one second, so frame the belt before opening this screen.
3. Drag the amber box over the logo (drag the corner dot to resize) and tap **Learn logo**.
4. Set the gate with the **Gate position** and **Gate width** sliders.
5. Run material through. The panel shows **SIGNAL 1** while the logo is inside the gate.
6. To pick a different logo, tap **Re-learn logo**, redraw the box and tap **Learn logo** again.

### Gate calibration

The gate width is stored as a fraction of the screen width, not in millimetres. To calibrate, place a known mark or ruler on the belt and adjust **Gate width** until the two lines span exactly 0.5 mm.

## Endpoint protocol

| Endpoint format | What is sent |
| --- | --- |
| `http://host:port/path` or `https://…` | `POST` with body `1` or `0` (`text/plain`) |
| `192.168.1.100:8080/signal` | Treated as `http://` |
| `tcp://host:port` | A line `1\n` or `0\n` over a kept-open socket |

A quick receiver for testing on your PC:

```bash
# TCP
nc -l 5000

# HTTP (Python)
python3 -c "
from http.server import *
class H(BaseHTTPRequestHandler):
    def do_POST(s):
        n=int(s.headers['Content-Length']); print(s.rfile.read(n).decode())
        s.send_response(200); s.end_headers()
HTTPServer(('',8080),H).serve_forever()"
```

## Tuning

| What | Where | Notes |
| --- | --- | --- |
| Match sensitivity | `matchThreshold` in `lib/vision/vision_worker.dart` | Lower to detect weaker matches, raise to reduce false triggers |
| Processing speed | `_procWidth` in the same file | Smaller = faster but less precise |
| Heartbeat interval | `Timer.periodic` in `tracker_controller.dart` | Default 200 ms |
| Focus-lock delay | `Future.delayed` in `tracker_controller.dart` | Raise if the image is blurry after locking |

## Troubleshooting

- **Logo shows as a red icon:** the asset path or `pubspec.yaml` indentation is wrong (`assets:` must sit under `flutter:`). Run `flutter clean` and rebuild.
- **`editing` / `startRelearn` not defined:** make sure `tracker_controller.dart` contains the `editing` field and `startRelearn()` method, then do a full restart.
- **No signal received:** check the endpoint, make sure the phone and receiver are on the same network, and confirm cleartext HTTP is allowed on Android.
- **Logo is not detected:** make sure the box tightly surrounds the logo, lighting is steady and focus is sharp. Try lowering `matchThreshold` slightly.
- **Focus keeps hunting:** some devices don't support `FocusMode.locked`. Log the exception in the `catch` block to confirm.
- **OpenCV compile errors:** the vision code uses `opencv_dart`, whose API changes between major versions. Check `vision_worker.dart` against the version in `pubspec.yaml`.

## Limitations

- Matching is not scale- or rotation-invariant. The logo should appear at a similar size and orientation to when it was learned.
- Accuracy and timing depend on the phone's camera frame rate and processing speed.
- The tracking screen is locked to landscape so image and overlay coordinates line up.

## License

Add your license here (for example MIT).# logo_tracker

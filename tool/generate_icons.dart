// Renders the app icon: a neon boxing glove in the LED-on-black language of
// the in-app display, with the amber/green/red stack lights above.
//
// Run explicitly (not part of the normal suite):
//   flutter test tool/generate_icons.dart
//
// Outputs to assets/icon/:
//   app_icon.png            1024x1024 full-bleed (iOS + Android legacy)
//   app_icon_green.png      1024x1024 alternate in work-green
//   app_icon_foreground.png 1080x1080 transparent, content in the adaptive
//                           safe zone (Android adaptive foreground)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:round_timer/theme/led_theme.dart';

/// Neon-sign boxing glove: union of fist, thumb, and cuff, stroked in glow.
/// Geometry is authored on a 1024 grid and scaled by [s].
Path _glovePath(double s) {
  Path oval(double cx, double cy, double rx, double ry, [double rot = 0]) {
    final p = Path()
      ..addOval(Rect.fromCenter(
          center: Offset.zero, width: rx * 2, height: ry * 2));
    final m = Matrix4.identity()
      ..translateByDouble(cx * s, cy * s, 0, 1)
      ..rotateZ(rot);
    return p.transform(m.storage);
  }

  // Fist body — big rounded mass, slightly taller than wide.
  final body = oval(536, 430, 252, 274);
  // Thumb — angled pad on the left front.
  final thumb = oval(298, 512, 108, 156, -0.30);
  // Cuff — wrist band below the fist.
  final cuff = Path()
    ..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(408 * s, 640 * s, 668 * s, 856 * s),
      Radius.circular(52 * s),
    ));

  var glove = Path.combine(PathOperation.union, body, thumb);
  glove = Path.combine(PathOperation.union, glove, cuff);
  return glove;
}

/// Wrist seam — a lace-line detail across the glove where cuff meets fist.
Path _seamPath(double s) => Path()
  ..moveTo(420 * s, 668 * s)
  ..quadraticBezierTo(538 * s, 726 * s, 656 * s, 668 * s);

void _drawIcon(
  Canvas canvas, {
  required double size,
  required Color neon,
  required bool background,
  required double contentScale,
}) {
  if (background) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      Paint()..color = LedColors.bg,
    );
  }

  final s = (size / 1024) * contentScale;
  // Center the scaled 1024-grid composition.
  final offset = (size - 1024 * s) / 2;
  canvas.save();
  canvas.translate(offset, offset);

  final glove = _glovePath(s);
  final seam = _seamPath(s);
  final strokeW = 30 * s;

  // Stack lights above the glove, green (work) lit — mid-round on the wall.
  final dotR = 26 * s;
  final dotGap = dotR * 3.4;
  final colors = [LedColors.amber, LedColors.green, LedColors.red];
  for (var i = 0; i < 3; i++) {
    final c = Offset(512 * s + (i - 1) * dotGap, 96 * s);
    final on = i == 1;
    if (on) {
      canvas.drawCircle(
        c,
        dotR * 1.6,
        Paint()
          ..color = colors[i].withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotR),
      );
    }
    canvas.drawCircle(
      c,
      dotR,
      Paint()..color = on ? colors[i] : colors[i].withValues(alpha: 0.28),
    );
  }

  // Faint fill so the glove reads as a solid object, not just wire.
  canvas.drawPath(glove, Paint()..color = neon.withValues(alpha: 0.08));

  // Neon tube: wide soft glow, tighter halo, then the crisp stroke.
  final glowWide = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW * 1.6
    ..color = neon.withValues(alpha: 0.30)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 34 * s);
  final glowTight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..color = neon.withValues(alpha: 0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * s);
  final tube = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..strokeCap = StrokeCap.round
    ..color = neon;

  for (final path in [glove, seam]) {
    canvas.drawPath(path, glowWide);
    canvas.drawPath(path, glowTight);
    canvas.drawPath(path, tube);
  }

  canvas.restore();
}

Future<void> _render(
  String path, {
  required int size,
  required Color neon,
  required bool background,
  required double contentScale,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _drawIcon(
    canvas,
    size: size.toDouble(),
    neon: neon,
    background: background,
    contentScale: contentScale,
  );
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate app icons', (tester) async {
    await tester.runAsync(() async {
      await _render(
        'assets/icon/app_icon.png',
        size: 1024,
        neon: LedColors.red,
        background: true,
        contentScale: 1.0,
      );
      await _render(
        'assets/icon/app_icon_green.png',
        size: 1024,
        neon: LedColors.green,
        background: true,
        contentScale: 1.0,
      );
      await _render(
        'assets/icon/app_icon_foreground.png',
        size: 1080,
        neon: LedColors.red,
        background: false,
        contentScale: 0.62,
      );
    });
  });
}

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

/// Upright boxing glove silhouette (like the glove emoji): big fist mass,
/// thumb lobe on the left, cuff band below. Filled union of three shapes;
/// seam lines are cut in background color on top. 1024 grid, scaled by [s].
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

  // Fist — big mass, biased right so the glove is asymmetric.
  final fist = oval(572, 420, 265, 260);
  // Thumb — clear lobe on the lower left.
  final thumb = oval(330, 545, 115, 150, -0.20);
  // Cuff — band below, tucked inside the fist's width so the union stays
  // smooth (no stepped shoulders).
  final cuff = Path()
    ..addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(572 * s, 730 * s), width: 300 * s, height: 240 * s),
      Radius.circular(58 * s),
    ));

  var glove = Path.combine(PathOperation.union, fist, thumb);
  glove = Path.combine(PathOperation.union, glove, cuff);
  return glove;
}

/// Seams drawn in background color over the fill: the cuff line and the
/// thumb crease — what makes the silhouette read "glove", not "blob".
Path _seamPath(double s) => Path()
  // Cuff seam — slight downward arc across the wrist.
  ..moveTo(440 * s, 640 * s)
  ..quadraticBezierTo(572 * s, 692 * s, 704 * s, 640 * s)
  // Thumb crease — along the inner edge of the thumb lobe.
  ..moveTo(450 * s, 440 * s)
  ..cubicTo(380 * s, 480 * s, 372 * s, 560 * s, 415 * s, 640 * s);

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

  // Solid silhouette over a soft LED glow.
  canvas.drawPath(
    glove,
    Paint()
      ..color = neon.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * s),
  );
  canvas.drawPath(glove, Paint()..color = neon);

  // Seams cut into the fill in panel color give it the glove anatomy.
  canvas.drawPath(
    seam,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.8
      ..strokeCap = StrokeCap.round
      ..color = LedColors.bg,
  );

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

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

/// Raised fist with hand wraps, viewed from the back of the hand — the
/// sport-agnostic combat mark (boxing, MMA, Muay Thai, grappling). Four
/// knuckle bumps on top are what make the silhouette unmistakably a fist.
/// Authored on a 1024 grid, scaled by [s].
Path _glovePath(double s) {
  final p = Path()
    // Bottom-left of the forearm, up the left side.
    ..moveTo(395 * s, 880 * s)
    ..lineTo(390 * s, 700 * s)
    // Palm-left bulge.
    ..cubicTo(378 * s, 660 * s, 340 * s, 640 * s, 332 * s, 560 * s)
    ..cubicTo(324 * s, 480 * s, 330 * s, 420 * s, 352 * s, 385 * s)
    // Knuckles: index, middle, ring, pinky — bumps with valleys between.
    ..cubicTo(360 * s, 330 * s, 400 * s, 305 * s, 438 * s, 330 * s)
    ..quadraticBezierTo(458 * s, 344 * s, 466 * s, 352 * s)
    ..cubicTo(478 * s, 300 * s, 520 * s, 295 * s, 548 * s, 330 * s)
    ..quadraticBezierTo(562 * s, 346 * s, 572 * s, 352 * s)
    ..cubicTo(582 * s, 302 * s, 622 * s, 300 * s, 648 * s, 335 * s)
    ..quadraticBezierTo(660 * s, 350 * s, 668 * s, 356 * s)
    ..cubicTo(678 * s, 318 * s, 706 * s, 320 * s, 722 * s, 355 * s)
    // Right edge down to the thumb.
    ..cubicTo(738 * s, 400 * s, 742 * s, 440 * s, 738 * s, 470 * s)
    // Thumb curled across the side.
    ..cubicTo(782 * s, 505 * s, 790 * s, 585 * s, 752 * s, 648 * s)
    ..cubicTo(726 * s, 690 * s, 680 * s, 700 * s, 648 * s, 692 * s)
    // Into the wrist and down the right side of the forearm.
    ..cubicTo(636 * s, 700 * s, 634 * s, 720 * s, 634 * s, 760 * s)
    ..lineTo(634 * s, 880 * s)
    // Rounded cut at the bottom of the forearm.
    ..cubicTo(620 * s, 906 * s, 410 * s, 906 * s, 395 * s, 880 * s)
    ..close();
  return p;
}

/// Detail cuts in panel color: finger gaps under the knuckle valleys, the
/// thumb crease, and the hand-wrap bands across wrist and palm.
Path _seamPath(double s) => Path()
  // Finger gaps.
  ..moveTo(462 * s, 372 * s)
  ..lineTo(456 * s, 470 * s)
  ..moveTo(568 * s, 370 * s)
  ..lineTo(562 * s, 470 * s)
  ..moveTo(664 * s, 374 * s)
  ..lineTo(660 * s, 465 * s)
  // Thumb crease.
  ..moveTo(734 * s, 490 * s)
  ..quadraticBezierTo(692 * s, 552 * s, 672 * s, 655 * s)
  // Palm wrap band — angled across the hand, stopping short of the thumb.
  ..moveTo(338 * s, 528 * s)
  ..lineTo(662 * s, 585 * s)
  // Wrist wrap bands.
  ..moveTo(398 * s, 742 * s)
  ..lineTo(630 * s, 728 * s)
  ..moveTo(400 * s, 802 * s)
  ..lineTo(630 * s, 790 * s);

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

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
    // Bottom-left of the forearm, up the left side. Thick wrist.
    ..moveTo(385 * s, 890 * s)
    ..lineTo(382 * s, 700 * s)
    // Palm-left bulge.
    ..cubicTo(368 * s, 660 * s, 322 * s, 645 * s, 314 * s, 555 * s)
    ..cubicTo(306 * s, 470 * s, 315 * s, 415 * s, 338 * s, 382 * s)
    // Knuckles: index, middle, ring, pinky — big squared-off bumps.
    ..cubicTo(348 * s, 318 * s, 398 * s, 292 * s, 442 * s, 322 * s)
    ..quadraticBezierTo(462 * s, 338 * s, 472 * s, 344 * s)
    ..cubicTo(482 * s, 288 * s, 532 * s, 282 * s, 562 * s, 320 * s)
    ..quadraticBezierTo(576 * s, 338 * s, 586 * s, 342 * s)
    ..cubicTo(596 * s, 292 * s, 640 * s, 290 * s, 668 * s, 326 * s)
    ..quadraticBezierTo(680 * s, 344 * s, 688 * s, 350 * s)
    ..cubicTo(700 * s, 314 * s, 730 * s, 318 * s, 746 * s, 356 * s)
    // Right edge down to the thumb.
    ..cubicTo(762 * s, 400 * s, 766 * s, 442 * s, 760 * s, 472 * s)
    // Thumb curled across the side.
    ..cubicTo(806 * s, 508 * s, 814 * s, 590 * s, 774 * s, 652 * s)
    ..cubicTo(746 * s, 694 * s, 698 * s, 704 * s, 664 * s, 696 * s)
    // Into the wrist and down the right side of the forearm.
    ..cubicTo(652 * s, 704 * s, 650 * s, 724 * s, 650 * s, 760 * s)
    ..lineTo(650 * s, 890 * s)
    // Rounded cut at the bottom of the forearm.
    ..cubicTo(634 * s, 916 * s, 400 * s, 916 * s, 385 * s, 890 * s)
    ..close();
  return p;
}

/// Detail cuts in panel color: finger gaps under the knuckle valleys, the
/// thumb crease, and the hand-wrap bands across wrist and palm.
Path _seamPath(double s) => Path()
  // Finger gaps — down through the white knuckle wrap.
  ..moveTo(470 * s, 360 * s)
  ..lineTo(462 * s, 452 * s)
  ..moveTo(584 * s, 356 * s)
  ..lineTo(576 * s, 452 * s)
  ..moveTo(686 * s, 362 * s)
  ..lineTo(680 * s, 450 * s)
  // Thumb crease.
  ..moveTo(756 * s, 492 * s)
  ..quadraticBezierTo(712 * s, 556 * s, 690 * s, 660 * s)
  // Separation lines across the white wrist wrap.
  ..moveTo(392 * s, 768 * s)
  ..lineTo(648 * s, 752 * s)
  ..moveTo(394 * s, 830 * s)
  ..lineTo(648 * s, 816 * s);

/// Wrap bands as filled strips (intersected with the fist silhouette):
/// the wrist fully wrapped plus one angled palm band.
Path _wrapBandsPath(double s, Path glove) {
  final bands = Path()
    // Knuckle wrap — covers the knuckle ridge like a real wrap job.
    ..addPolygon([
      Offset(280 * s, 270 * s),
      Offset(800 * s, 270 * s),
      Offset(800 * s, 462 * s),
      Offset(280 * s, 462 * s),
    ], true)
    // Diagonal band across the back of the hand, up toward the thumb.
    ..addPolygon([
      Offset(300 * s, 592 * s),
      Offset(770 * s, 474 * s),
      Offset(770 * s, 545 * s),
      Offset(300 * s, 663 * s),
    ], true)
    // Wrist — fully wrapped.
    ..addPolygon([
      Offset(365 * s, 705 * s),
      Offset(668 * s, 688 * s),
      Offset(668 * s, 920 * s),
      Offset(365 * s, 920 * s),
    ], true);
  return Path.combine(PathOperation.intersect, bands, glove);
}

/// Ringside trip-gong fight bell, modeled on the real hardware: a round
/// brass bell disc with a center bolt on a square wooden backboard, with
/// the L-shaped hammer arm anchored at the top edge, hanging down beside
/// the bell with its striker bent into the rim. 1024 grid, scaled by [s].
void _drawBell(Canvas canvas, double s, Color accent, Color bg) {
  final bellCenter = Offset(490 * s, 570 * s);
  final r = 252 * s;

  // Combat palette: hot red bell, gold mallet and sound.
  const bellCore = Color(0xFFFF5A3C);
  const bellEdge = Color(0xFFD81E12);
  const rimLight = Color(0xFFFF8A66);
  const glowRed = Color(0xFFFF3B2A);

  // Two-layer bloom: wide soft wash + tight hot halo.
  canvas.drawCircle(
    bellCenter,
    r * 1.06,
    Paint()
      ..color = glowRed.withValues(alpha: 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 80 * s),
  );
  canvas.drawCircle(
    bellCenter,
    r,
    Paint()
      ..color = glowRed.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 * s),
  );

  // Bell disc — radial gradient, hot at the strike, deep at the rim.
  canvas.drawCircle(
    bellCenter,
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(bellCenter.dx + r * 0.18, bellCenter.dy - r * 0.22),
        r * 1.35,
        [bellCore, bellEdge],
        [0.15, 1.0],
      ),
  );
  // Bright rim catch-light for pop, strongest toward the impact side.
  canvas.drawCircle(
    bellCenter,
    r - 5 * s,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * s
      ..color = rimLight.withValues(alpha: 0.85),
  );
  canvas.drawCircle(bellCenter, 36 * s, Paint()..color = bg);

  // Gold mallet mid-swing at the upper right, head just off the rim.
  canvas.drawLine(
    Offset(892 * s, 196 * s),
    Offset(756 * s, 334 * s),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44 * s
      ..strokeCap = StrokeCap.round
      ..color = accent,
  );
  canvas.drawCircle(
    Offset(738 * s, 352 * s),
    62 * s,
    Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22 * s),
  );
  canvas.drawCircle(Offset(738 * s, 352 * s), 62 * s, Paint()..color = accent);

  // Gold vibration arcs hugging the rim — the bell is ringing.
  final arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 24 * s
    ..strokeCap = StrokeCap.round
    ..color = accent;
  canvas.drawArc(
    Rect.fromCircle(center: bellCenter, radius: r + 62 * s),
    2.55, // left side, upper
    0.85,
    false,
    arcPaint,
  );
  canvas.drawArc(
    Rect.fromCircle(center: bellCenter, radius: r + 130 * s),
    2.70,
    0.55,
    false,
    arcPaint..color = accent.withValues(alpha: 0.55),
  );
  // Strike ticks at the impact point.
  final mark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20 * s
    ..strokeCap = StrokeCap.round
    ..color = accent;
  canvas.drawLine(Offset(826 * s, 430 * s), Offset(778 * s, 452 * s), mark);
  canvas.drawLine(Offset(852 * s, 530 * s), Offset(800 * s, 536 * s), mark);
}

enum IconMark { fist, bell }

void _drawIcon(
  Canvas canvas, {
  required double size,
  required Color neon,
  required bool background,
  required double contentScale,
  IconMark mark = IconMark.fist,
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

  if (mark == IconMark.bell) {
    _drawBell(canvas, s, neon, LedColors.bg);
    canvas.restore();
    return;
  }

  // Solid silhouette over a soft LED glow.
  canvas.drawPath(
    glove,
    Paint()
      ..color = neon.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * s),
  );
  canvas.drawPath(glove, Paint()..color = neon);

  // Hand wraps in off-white over the fist.
  canvas.drawPath(
      _wrapBandsPath(s, glove), Paint()..color = LedColors.text);

  // Seams cut into the fill in panel color give it the anatomy.
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
  IconMark mark = IconMark.fist,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _drawIcon(
    canvas,
    size: size.toDouble(),
    neon: neon,
    background: background,
    contentScale: contentScale,
    mark: mark,
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
        neon: LedColors.amber,
        background: true,
        contentScale: 1.0,
        mark: IconMark.bell,
      );
      await _render(
        'assets/icon/app_icon_fist.png',
        size: 1024,
        neon: LedColors.red,
        background: true,
        contentScale: 1.0,
      );
      await _render(
        'assets/icon/app_icon_foreground.png',
        size: 1080,
        neon: LedColors.amber,
        background: false,
        contentScale: 0.62,
        mark: IconMark.bell,
      );
    });
  });
}

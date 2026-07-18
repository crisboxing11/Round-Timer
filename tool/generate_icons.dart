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

/// Ring-side fight bell: round gong disc, center bolt, hammer at two
/// o'clock, strike marks. 1024 grid, scaled by [s].
void _drawBell(Canvas canvas, double s, Color brass, Color bg) {
  final center = Offset(500 * s, 560 * s);
  final r = 250 * s;

  // Glow + disc.
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..color = brass.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * s),
  );
  canvas.drawCircle(center, r, Paint()..color = brass);
  // Inner rim + center bolt, cut in panel color.
  canvas.drawCircle(
    center,
    r * 0.62,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22 * s
      ..color = bg,
  );
  canvas.drawCircle(center, 34 * s, Paint()..color = bg);

  // Hammer: shaft from upper-right toward the rim, round head at the rim.
  final shaft = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 46 * s
    ..strokeCap = StrokeCap.round
    ..color = brass;
  canvas.drawLine(
      Offset(858 * s, 176 * s), Offset(716 * s, 330 * s), shaft);
  canvas.drawCircle(Offset(700 * s, 348 * s), 64 * s, Paint()..color = brass);

  // Strike marks radiating from the impact point.
  final mark = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 22 * s
    ..strokeCap = StrokeCap.round
    ..color = brass;
  canvas.drawLine(Offset(560 * s, 208 * s), Offset(596 * s, 262 * s), mark);
  canvas.drawLine(Offset(800 * s, 480 * s), Offset(742 * s, 452 * s), mark);
  canvas.drawLine(Offset(690 * s, 180 * s), Offset(690 * s, 236 * s), mark);
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
        'assets/icon/app_icon_bell.png',
        size: 1024,
        neon: LedColors.amber,
        background: true,
        contentScale: 1.0,
        mark: IconMark.bell,
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

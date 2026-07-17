// Renders the app icon with the app's own seven-segment painter so the
// icon is pixel-identical to the in-app display.
//
// Run explicitly (not part of the normal suite):
//   flutter test tool/generate_icons.dart
//
// Outputs to assets/icon/:
//   app_icon.png            1024x1024 full-bleed (iOS + Android legacy)
//   app_icon_nodots.png     1024x1024 alternate without stack lights
//   app_icon_foreground.png 1080x1080 transparent, content in the adaptive
//                           safe zone (Android adaptive foreground)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:round_timer/screens/seven_segment.dart';
import 'package:round_timer/theme/led_theme.dart';

void _drawIcon(
  Canvas canvas, {
  required double size,
  required bool background,
  required bool stackDots,
  required double contentScale,
}) {
  if (background) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      Paint()..color = LedColors.bg,
    );
  }

  // Digit proportions match the in-app clock: width/height = 0.535.
  final digitH = size * 0.56 * contentScale;
  final digitW = digitH * 0.535;
  final gap = digitW * 0.30;
  final totalW = digitW * 2 + gap;
  final left = (size - totalW) / 2;
  // Center the full composition (dots row + digits) vertically.
  final dotR = size * 0.026 * contentScale;
  final dotsBlock = stackDots ? dotR * 2 + digitH * 0.16 : 0.0;
  final top = (size - digitH - dotsBlock) / 2 + dotsBlock;
  final glowSigma = digitH * 0.055;

  if (stackDots) {
    final colors = [LedColors.amber, LedColors.green, LedColors.red];
    final dotGap = dotR * 3.4;
    final cy = top - digitH * 0.16 - dotR;
    for (var i = 0; i < 3; i++) {
      final cx = size / 2 + (i - 1) * dotGap;
      final on = i == 1; // work green lit, like mid-round on the wall timer
      final c = colors[i];
      if (on) {
        canvas.drawCircle(
          Offset(cx, cy),
          dotR * 1.6,
          Paint()
            ..color = c.withValues(alpha: 0.35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotR),
        );
      }
      canvas.drawCircle(
        Offset(cx, cy),
        dotR,
        Paint()..color = on ? c : c.withValues(alpha: 0.28),
      );
    }
  }

  paintSevenSegmentDigit(
    canvas,
    Offset(left, top),
    digitW,
    digitH,
    1,
    color: LedColors.green,
    glowSigma: glowSigma,
  );
  paintSevenSegmentDigit(
    canvas,
    Offset(left + digitW + gap, top),
    digitW,
    digitH,
    2,
    color: LedColors.green,
    glowSigma: glowSigma,
  );
}

Future<void> _render(
  String path, {
  required int size,
  required bool background,
  required bool stackDots,
  required double contentScale,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _drawIcon(
    canvas,
    size: size.toDouble(),
    background: background,
    stackDots: stackDots,
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
        background: true,
        stackDots: true,
        contentScale: 1.0,
      );
      await _render(
        'assets/icon/app_icon_nodots.png',
        size: 1024,
        background: true,
        stackDots: false,
        contentScale: 1.0,
      );
      await _render(
        'assets/icon/app_icon_foreground.png',
        size: 1080,
        background: false,
        stackDots: true,
        contentScale: 0.62,
      );
    });
  });
}

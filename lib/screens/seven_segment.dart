import 'package:flutter/material.dart';
import '../theme/led_theme.dart';

/// MM:SS seven-segment display, painted like a physical gym LED timer,
/// including ghosted unlit segments.
class SevenSegmentClock extends StatelessWidget {
  const SevenSegmentClock({
    super.key,
    required this.duration,
    required this.color,
    this.blinkColon = true,
  });

  final Duration duration;
  final Color color;
  final bool blinkColon;

  @override
  Widget build(BuildContext context) {
    final secs = (duration.inMilliseconds / 1000).ceil();
    final mm = secs ~/ 60;
    final ss = secs % 60;
    return AspectRatio(
      aspectRatio: 13 / 4.6,
      child: CustomPaint(
        painter: _ClockPainter(
          digits: [mm ~/ 10, mm % 10, ss ~/ 10, ss % 10],
          color: color,
          colonOn: blinkColon,
        ),
      ),
    );
  }
}

const _digitSegments = <int, String>{
  0: 'abcdef', 1: 'bc', 2: 'abged', 3: 'abgcd', 4: 'fgbc',
  5: 'afgcd', 6: 'afgedc', 7: 'abc', 8: 'abcdefg', 9: 'abcfgd',
};

/// Paints one seven-segment digit (lit segments + ghosts) at [o] sized
/// [w]×[h]. Shared by the clock painter and the app-icon generator so the
/// icon glyphs are pixel-identical to the in-app display.
void paintSevenSegmentDigit(
  Canvas c,
  Offset o,
  double w,
  double h,
  int d, {
  required Color color,
  required double glowSigma,
  Color ghostColor = LedColors.ghost,
}) {
  final lit = _digitSegments[d] ?? '';
  final t = w * 0.16; // segment thickness
  final litPaint = Paint()..color = color;
  final ghostPaint = Paint()..color = ghostColor;
  final glow = Paint()
    ..color = color.withValues(alpha: 0.35)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma);

  Path hSeg(double y) =>
      _hexPath(o.dx + t * 0.6, o.dy + y, w - t * 1.2, t, horizontal: true);
  Path vSeg(double x, double y) =>
      _hexPath(o.dx + x, o.dy + y, t, h / 2 - t, horizontal: false);

  final segs = <String, Path>{
    'a': hSeg(0),
    'g': hSeg(h / 2 - t / 2),
    'd': hSeg(h - t),
    'f': vSeg(0, t * 0.7),
    'b': vSeg(w - t, t * 0.7),
    'e': vSeg(0, h / 2 + t * 0.3),
    'c': vSeg(w - t, h / 2 + t * 0.3),
  };

  segs.forEach((k, path) {
    if (lit.contains(k)) {
      c.drawPath(path, glow);
      c.drawPath(path, litPaint);
    } else {
      c.drawPath(path, ghostPaint);
    }
  });
}

Path _hexPath(double x, double y, double w, double h,
    {required bool horizontal}) {
  final p = Path();
  if (horizontal) {
    final k = h / 2;
    p
      ..moveTo(x, y + k)
      ..lineTo(x + k, y)
      ..lineTo(x + w - k, y)
      ..lineTo(x + w, y + k)
      ..lineTo(x + w - k, y + h)
      ..lineTo(x + k, y + h)
      ..close();
  } else {
    final k = w / 2;
    p
      ..moveTo(x + k, y)
      ..lineTo(x + w, y + k)
      ..lineTo(x + w, y + h - k)
      ..lineTo(x + k, y + h)
      ..lineTo(x, y + h - k)
      ..lineTo(x, y + k)
      ..close();
  }
  return p;
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.digits, required this.color, required this.colonOn});
  final List<int> digits;
  final Color color;
  final bool colonOn;

  @override
  void paint(Canvas canvas, Size size) {
    // Layout: 4 digits (3 units each) + colon (1 unit) = 13 units wide.
    final unit = size.width / 13;
    final digitW = unit * 3 * 0.82;
    final h = size.height;
    final xs = [0.0, unit * 3, unit * 7, unit * 10];

    for (var i = 0; i < 4; i++) {
      paintSevenSegmentDigit(
        canvas,
        Offset(xs[i] + unit * 0.25, 0),
        digitW,
        h,
        digits[i],
        color: color,
        glowSigma: 10,
      );
    }
    _paintColon(canvas, Offset(unit * 6.15, 0), unit * 0.7, h);
  }

  void _paintColon(Canvas c, Offset o, double s, double h) {
    if (!colonOn) return;
    final paint = Paint()..color = color;
    for (final fy in [0.33, 0.67]) {
      c.save();
      c.translate(o.dx + s / 2, h * fy);
      c.rotate(0.785398); // 45°
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.8, height: s * 0.8), paint);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.digits.toString() != digits.toString() ||
      old.color != color ||
      old.colonOn != colonOn;
}

import 'package:flutter/material.dart';
import '../models/models.dart';

/// The physical gym timer color language.
abstract class LedColors {
  static const bg = Color(0xFF0A0B0A);
  static const panel = Color(0xFF101210);
  static const border = Color(0xFF222622);
  static const ghost = Color(0xFF161917); // unlit LED segments
  static const text = Color(0xFFEDEFEA);
  static const textDim = Color(0xFF8A918A);
  static const textFaint = Color(0xFF565C56);

  static const amber = Color(0xFFFFB324); // prep + 10s warning
  static const green = Color(0xFF3DF25B); // work
  static const red = Color(0xFFFF3B3B); // rest

  static Color forPhase(PhaseType t, {bool warning = false}) {
    if (warning) return amber;
    switch (t) {
      case PhaseType.prep:
        return amber;
      case PhaseType.work:
        return green;
      case PhaseType.rest:
        return red;
    }
  }
}

abstract class LedText {
  static const _family = 'BarlowCondensed'; // falls back to default until bundled

  static const eyebrow = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 4.5,
    color: LedColors.textDim,
  );

  static const roundLabel = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 5,
    color: LedColors.textDim,
  );

  static const stateLabel = TextStyle(
    fontFamily: _family,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: 8,
  );

  static const presetName = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
    color: LedColors.text,
  );

  static const presetSub = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    color: LedColors.textDim,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

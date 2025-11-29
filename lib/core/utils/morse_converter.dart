import '../constants/app_constants.dart';

/// Represents a single morse code element (dot or dash)
class MorseElement {
  final bool isDot;
  final int duration;

  const MorseElement.dot() : isDot = true, duration = MorseCode.dotDuration;

  const MorseElement.dash() : isDot = false, duration = MorseCode.dashDuration;
}

/// Represents a vibration pattern with duration and pause
class VibrationPattern {
  final List<int> pattern;
  final List<int> intensities;

  const VibrationPattern({required this.pattern, required this.intensities});

  /// Creates an empty pattern
  factory VibrationPattern.empty() =>
      const VibrationPattern(pattern: [], intensities: []);
}

/// Utility class to convert text to morse code vibration patterns
class MorseConverter {
  MorseConverter._();

  /// Convert a morse code string (dots and dashes) to vibration pattern
  static VibrationPattern morseToVibration(String morseCode) {
    if (morseCode.isEmpty) return VibrationPattern.empty();

    final pattern = <int>[];
    final intensities = <int>[];

    for (int i = 0; i < morseCode.length; i++) {
      final char = morseCode[i];

      if (char == '.') {
        pattern.add(MorseCode.dotDuration);
        intensities.add(255);
      } else if (char == '-') {
        pattern.add(MorseCode.dashDuration);
        intensities.add(255);
      } else if (char == ' ') {
        pattern.add(MorseCode.wordGap);
        intensities.add(0);
        continue;
      } else {
        continue;
      }

      // Add gap after symbol (unless it's the last one)
      if (i < morseCode.length - 1) {
        pattern.add(MorseCode.symbolGap);
        intensities.add(0);
      }
    }

    return VibrationPattern(pattern: pattern, intensities: intensities);
  }

  /// Convert text to morse code string
  static String textToMorse(String text) {
    final buffer = StringBuffer();
    final upperText = text.toUpperCase();

    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      final morse = MorseCode.alphabet[char];

      if (morse != null) {
        buffer.write(morse);
        // Add letter gap between characters (not after space)
        if (i < upperText.length - 1 && char != ' ') {
          buffer.write(' ');
        }
      }
    }

    return buffer.toString();
  }

  /// Convert text directly to vibration pattern
  static VibrationPattern textToVibration(String text) {
    final morseCode = textToMorse(text);
    return morseToVibration(morseCode);
  }

  /// Create a danger alert vibration pattern based on level
  static VibrationPattern createDangerPattern(int level) {
    // Level 0-4: more intense patterns for higher danger levels
    final basePattern = switch (level) {
      0 => [100], // Safe - single short pulse
      1 => [100, 50, 100], // Caution - two short pulses
      2 => [200, 100, 200], // Warning - two medium pulses
      3 => [300, 100, 300, 100, 300], // Danger - three long pulses
      _ => [500, 100, 500, 100, 500, 100, 500], // Critical - continuous alarm
    };

    final intensities = List.filled(basePattern.length, 255);

    return VibrationPattern(pattern: basePattern, intensities: intensities);
  }
}

import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/danger_detector.dart';
import '../../core/utils/morse_converter.dart';

/// Repository interface for feedback operations (TTS and Haptic)
/// Follows Interface Segregation Principle (ISP)
abstract class FeedbackRepository {
  /// Initialize text-to-speech engine
  Future<Either<Failure, void>> initializeTTS();

  /// Speak the given text
  Future<Either<Failure, void>> speak(String text);

  /// Stop speaking
  Future<void> stopSpeaking();

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate);

  /// Set speech pitch (0.5 to 2.0)
  Future<void> setSpeechPitch(double pitch);

  /// Check if TTS is speaking
  bool get isSpeaking;

  /// Vibrate with a custom pattern
  Future<Either<Failure, void>> vibrate(VibrationPattern pattern);

  /// Vibrate morse code for given text
  Future<Either<Failure, void>> vibrateMorseCode(String morseCode);

  /// Vibrate danger alert based on level
  Future<Either<Failure, void>> vibrateDangerAlert(DangerLevel level);

  /// Single short vibration
  Future<void> vibrateShort();

  /// Check if device has vibration capability
  Future<bool> hasVibrator();

  /// Cancel ongoing vibration
  Future<void> cancelVibration();
}

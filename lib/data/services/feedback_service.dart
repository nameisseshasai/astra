import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/danger_detector.dart';
import '../../core/utils/morse_converter.dart';

/// Service for handling text-to-speech and haptic feedback
/// OPTIMIZED for DeafBlind users
class FeedbackService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _isInitialized = false;

  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  /// Initialize the TTS engine
  Future<void> initializeTTS() async {
    debugPrint('=== Initializing TTS ===');
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Clear speech rate
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        debugPrint('TTS started speaking');
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        debugPrint('TTS completed');
        _isSpeaking = false;
      });
      _tts.setCancelHandler(() {
        debugPrint('TTS cancelled');
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('TTS init failed: $e');
      throw TTSException(message: 'Failed to initialize TTS: $e');
    }
  }

  /// Speak the given text - ALWAYS runs for scene analysis
  Future<void> speak(String text) async {
    debugPrint('=== TTS Speak Called ===');
    debugPrint('Text: "$text"');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Is speaking: $_isSpeaking');
    
    if (!_isInitialized) {
      debugPrint('ERROR: TTS not initialized!');
      // Try to initialize
      try {
        await initializeTTS();
      } catch (e) {
        debugPrint('Auto-init failed: $e');
        throw TTSException(message: 'TTS not initialized');
      }
    }

    try {
      if (_isSpeaking) {
        debugPrint('Stopping current speech');
        await stopSpeaking();
      }
      
      debugPrint('Calling _tts.speak()');
      final result = await _tts.speak(text);
      debugPrint('_tts.speak() result: $result');
    } catch (e) {
      debugPrint('Speak error: $e');
      throw TTSException(message: 'Failed to speak: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Set speech pitch (0.5 to 2.0)
  Future<void> setSpeechPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
  }

  /// Vibrate with a custom pattern
  Future<void> vibrate(VibrationPattern pattern) async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib != true || pattern.pattern.isEmpty) return;
      await Vibration.vibrate(pattern: pattern.pattern);
    } catch (e) {
      throw HapticException(message: 'Vibration failed: $e');
    }
  }

  /// Vibrate morse code for given morse pattern
  Future<void> vibrateMorseCode(String morseCode) async {
    try {
      final pattern = MorseConverter.morseToVibration(morseCode);
      await vibrate(pattern);
    } catch (e) {
      throw HapticException(message: 'Morse vibration failed: $e');
    }
  }

  /// ENHANCED: Vibrate danger alert with EXTENDED DURATION based on level
  /// Critical = long continuous, Danger = pulsed, Warning = short
  Future<void> vibrateDangerAlert(DangerLevel level) async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib != true) return;

      switch (level) {
        case DangerLevel.critical:
          // CRITICAL: Long continuous vibration + 3 pulses
          await Vibration.vibrate(duration: HapticConfig.criticalDurationMs);
          await Future.delayed(const Duration(milliseconds: 200));
          await _vibratePulses(3, 300, 100);
          break;
          
        case DangerLevel.danger:
          // DANGER: Multiple strong pulses
          await _vibratePulses(
            HapticConfig.dangerPulseCount,
            HapticConfig.dangerDurationMs ~/ HapticConfig.dangerPulseCount,
            HapticConfig.pulseGapMs,
          );
          break;
          
        case DangerLevel.warning:
          // WARNING: Medium vibration with 2 pulses
          await _vibratePulses(2, HapticConfig.warningDurationMs ~/ 2, 100);
          break;
          
        case DangerLevel.caution:
          // CAUTION: Short single vibration
          await Vibration.vibrate(duration: HapticConfig.cautionDurationMs);
          break;
          
        case DangerLevel.safe:
          // SAFE: Gentle confirmation tap
          await Vibration.vibrate(duration: HapticConfig.safeDurationMs);
          break;
      }
    } catch (e) {
      throw HapticException(message: 'Danger alert failed: $e');
    }
  }

  /// Helper: Create pulsed vibration pattern
  Future<void> _vibratePulses(int count, int durationMs, int gapMs) async {
    final pattern = <int>[0]; // Start with 0 delay
    for (int i = 0; i < count; i++) {
      pattern.add(durationMs);
      if (i < count - 1) pattern.add(gapMs);
    }
    await Vibration.vibrate(pattern: pattern);
  }

  /// Safe confirmation vibration - gentle feedback
  Future<void> vibrateSafeConfirmation() async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib != true) return;
      await Vibration.vibrate(duration: HapticConfig.safeDurationMs);
    } catch (_) {}
  }

  /// Single short vibration
  Future<void> vibrateShort() async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib != true) return;
      await Vibration.vibrate(duration: 100);
    } catch (_) {}
  }

  /// Check if device has vibration capability
  Future<bool> hasVibrator() async {
    final result = await Vibration.hasVibrator();
    return result == true;
  }

  /// Cancel ongoing vibration
  Future<void> cancelVibration() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  /// Dispose resources
  void dispose() {
    _tts.stop();
  }
}

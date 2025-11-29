import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/danger_detector.dart';
import '../../core/utils/morse_converter.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../services/feedback_service.dart';

/// Implementation of FeedbackRepository
/// Follows Dependency Inversion Principle (DIP)
class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackService _feedbackService;

  FeedbackRepositoryImpl(this._feedbackService);

  @override
  Future<Either<Failure, void>> initializeTTS() async {
    try {
      await _feedbackService.initializeTTS();
      return const Right(null);
    } on TTSException catch (e) {
      return Left(TTSFailure(message: e.message));
    } catch (e) {
      return Left(TTSFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> speak(String text) async {
    try {
      await _feedbackService.speak(text);
      return const Right(null);
    } on TTSException catch (e) {
      return Left(TTSFailure(message: e.message));
    } catch (e) {
      return Left(TTSFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<void> stopSpeaking() async {
    await _feedbackService.stopSpeaking();
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _feedbackService.setSpeechRate(rate);
  }

  @override
  Future<void> setSpeechPitch(double pitch) async {
    await _feedbackService.setSpeechPitch(pitch);
  }

  @override
  bool get isSpeaking => _feedbackService.isSpeaking;

  @override
  Future<Either<Failure, void>> vibrate(VibrationPattern pattern) async {
    try {
      await _feedbackService.vibrate(pattern);
      return const Right(null);
    } on HapticException catch (e) {
      return Left(HapticFailure(message: e.message));
    } catch (e) {
      return Left(HapticFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> vibrateMorseCode(String morseCode) async {
    try {
      await _feedbackService.vibrateMorseCode(morseCode);
      return const Right(null);
    } on HapticException catch (e) {
      return Left(HapticFailure(message: e.message));
    } catch (e) {
      return Left(HapticFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> vibrateDangerAlert(DangerLevel level) async {
    try {
      await _feedbackService.vibrateDangerAlert(level);
      return const Right(null);
    } on HapticException catch (e) {
      return Left(HapticFailure(message: e.message));
    } catch (e) {
      return Left(HapticFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<void> vibrateShort() async {
    await _feedbackService.vibrateShort();
  }

  @override
  Future<bool> hasVibrator() async {
    return await _feedbackService.hasVibrator();
  }

  @override
  Future<void> cancelVibration() async {
    await _feedbackService.cancelVibration();
  }
}

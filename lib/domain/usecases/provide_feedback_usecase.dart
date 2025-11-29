import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/danger_detector.dart';
import '../entities/scene_analysis.dart';
import '../repositories/feedback_repository.dart';

/// Use case for providing feedback to the user
/// Follows Single Responsibility Principle (SRP)
class ProvideFeedbackUseCase {
  final FeedbackRepository _feedbackRepository;

  const ProvideFeedbackUseCase(this._feedbackRepository);

  /// Provide complete feedback for a scene analysis
  Future<Either<Failure, void>> call(
    SceneAnalysis analysis, {
    required bool enableVoice,
    required bool enableHaptic,
    required bool enableDangerAlerts,
  }) async {
    // Provide haptic feedback first (faster response)
    if (enableHaptic) {
      if (enableDangerAlerts && analysis.isDangerous) {
        await _feedbackRepository.vibrateDangerAlert(analysis.dangerInfo.level);
      } else {
        await _feedbackRepository.vibrateMorseCode(
          analysis.dangerInfo.morsePattern,
        );
      }
    }

    // Provide voice feedback
    if (enableVoice) {
      String textToSpeak = analysis.description;

      // Prepend danger warning if dangerous
      if (enableDangerAlerts && analysis.isDangerous) {
        textToSpeak = '${analysis.dangerInfo.description}. $textToSpeak';
      }

      final result = await _feedbackRepository.speak(textToSpeak);
      if (result.isLeft()) {
        return result;
      }
    }

    return const Right(null);
  }

  /// Speak only the danger alert
  Future<Either<Failure, void>> speakDangerAlert(DangerInfo dangerInfo) async {
    return await _feedbackRepository.speak(dangerInfo.description);
  }

  /// Vibrate danger pattern only
  Future<Either<Failure, void>> vibrateDanger(DangerLevel level) async {
    return await _feedbackRepository.vibrateDangerAlert(level);
  }
}

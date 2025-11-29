import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../data/services/vision_service.dart';
import '../entities/scene_analysis.dart';
import '../repositories/vision_repository.dart';

/// Use case for analyzing a scene from camera image
/// Uses Cactus SDK's tool calling for danger detection and feedback
/// Follows Single Responsibility Principle (SRP)
class AnalyzeSceneUseCase {
  final VisionRepository _visionRepository;

  const AnalyzeSceneUseCase(this._visionRepository);

  /// Analyze image with tool calling and STREAMING (preferred method)
  /// This uses Cactus SDK's function calling for:
  /// - Danger detection
  /// - Morse code vibration
  /// - Text-to-speech
  /// 
  /// [onStreamChunk] - Optional callback for real-time streaming updates
  Future<Either<Failure, SceneAnalysis>> call(
    Uint8List imageBytes, {
    StreamingCallback? onStreamChunk,
  }) async {
    return await _visionRepository.analyzeImageWithTools(
      imageBytes,
      onStreamChunk: onStreamChunk,
    );
  }

  /// Legacy method without tool calling
  Future<Either<Failure, SceneAnalysis>> analyzeLegacy(
    Uint8List imageBytes,
  ) async {
    return await _visionRepository.analyzeImage(imageBytes);
  }
}

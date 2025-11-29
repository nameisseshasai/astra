import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../data/services/vision_service.dart';
import '../entities/app_state.dart';
import '../entities/scene_analysis.dart';

/// Repository interface for vision-related operations
/// Follows Interface Segregation Principle (ISP)
abstract class VisionRepository {
  /// Download the vision model with progress callback
  Future<Either<Failure, void>> downloadModel({
    required void Function(ModelDownloadProgress) onProgress,
  });

  /// Initialize the vision model for inference
  Future<Either<Failure, void>> initializeModel();

  /// Analyze an image and return scene description (legacy method)
  Future<Either<Failure, SceneAnalysis>> analyzeImage(Uint8List imageBytes);

  /// Analyze an image with tool calling for danger detection and feedback
  /// This method uses Cactus SDK's tool calling feature with STREAMING
  /// [onStreamChunk] - Optional callback for real-time streaming updates
  Future<Either<Failure, SceneAnalysis>> analyzeImageWithTools(
    Uint8List imageBytes, {
    StreamingCallback? onStreamChunk,
  });

  /// Check if model is downloaded
  Future<bool> isModelDownloaded();

  /// Check if model is initialized and ready
  bool isModelReady();

  /// Unload the model from memory
  Future<void> unloadModel();
}

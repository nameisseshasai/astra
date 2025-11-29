import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/app_state.dart';
import '../../domain/entities/scene_analysis.dart';
import '../../domain/repositories/vision_repository.dart';
import '../services/tool_executor_service.dart';
import '../services/vision_service.dart';

/// Implementation of VisionRepository with debug logging
class VisionRepositoryImpl implements VisionRepository {
  final VisionService _visionService;
  final ToolExecutorService _toolExecutorService;

  VisionRepositoryImpl(this._visionService, this._toolExecutorService);

  @override
  Future<Either<Failure, void>> downloadModel({
    required void Function(ModelDownloadProgress) onProgress,
  }) async {
    try {
      await _visionService.downloadModel(onProgress: onProgress);
      return const Right(null);
    } on ModelDownloadException catch (e) {
      return Left(ModelDownloadFailure(message: e.message));
    } catch (e) {
      return Left(ModelDownloadFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> initializeModel() async {
    try {
      await _visionService.initializeModel();
      return const Right(null);
    } on VisionException catch (e) {
      return Left(VisionFailure(message: e.message));
    } catch (e) {
      return Left(VisionFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, SceneAnalysis>> analyzeImage(
    Uint8List imageBytes,
  ) async {
    try {
      final description = await _visionService.analyzeImage(imageBytes);
      final analysis = SceneAnalysis.fromVisionResponse(description);
      return Right(analysis);
    } on VisionException catch (e) {
      return Left(VisionFailure(message: e.message));
    } catch (e) {
      return Left(VisionFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, SceneAnalysis>> analyzeImageWithTools(
    Uint8List imageBytes, {
    StreamingCallback? onStreamChunk,
  }) async {
    debugPrint('=== VisionRepository: analyzeImageWithTools ===');
    try {
      // Get vision analysis with streaming
      debugPrint('Calling vision service...');
      final visionResult = await _visionService.analyzeImageWithTools(
        imageBytes,
        onStreamChunk: onStreamChunk,
      );
      debugPrint('Vision result: ${visionResult.response}');

      // Execute tool calls for TTS and haptics
      debugPrint('Executing tool calls...');
      final executionResult = await _toolExecutorService.executeToolCalls(
        visionResult,
      );
      debugPrint('Execution complete. Tools: ${executionResult.executedTools}');

      // Create scene analysis
      final analysis = SceneAnalysis.fromToolExecution(executionResult);
      debugPrint('Analysis created: ${analysis.description}');

      return Right(analysis);
    } on VisionException catch (e) {
      debugPrint('Vision exception: ${e.message}');
      return Left(VisionFailure(message: e.message));
    } catch (e) {
      debugPrint('Unknown error: $e');
      return Left(VisionFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<bool> isModelDownloaded() async {
    return await _visionService.isModelDownloaded();
  }

  @override
  bool isModelReady() {
    return _visionService.isInitialized;
  }

  @override
  Future<void> unloadModel() async {
    _visionService.unloadModel();
  }
}

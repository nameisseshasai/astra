import 'dart:io';

import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/danger_detector.dart';
import '../../domain/entities/app_state.dart';
import 'tool_definitions.dart';

/// Data class to pass to isolate for image processing
class ImageProcessingParams {
  final Uint8List imageBytes;
  final String tempPath;

  const ImageProcessingParams({
    required this.imageBytes,
    required this.tempPath,
  });
}

/// Process image bytes in isolate (save to file)
Future<String> _processImageInIsolate(ImageProcessingParams params) async {
  final file = File(params.tempPath);
  await file.writeAsBytes(params.imageBytes);
  return params.tempPath;
}

/// Callback for streaming response chunks
typedef StreamingCallback = void Function(String chunk, bool isComplete);

/// Result of scene analysis with tool calls
class VisionAnalysisResult {
  final String response;
  final List<ToolCall> toolCalls;
  final bool success;
  final DangerInfo? parsedDangerInfo;
  final List<String> detectedObjects;
  final double? tokensPerSecond;
  final int? timeToFirstTokenMs;
  final String morsePattern;

  const VisionAnalysisResult({
    required this.response,
    required this.toolCalls,
    required this.success,
    this.parsedDangerInfo,
    this.detectedObjects = const [],
    this.tokensPerSecond,
    this.timeToFirstTokenMs,
    this.morsePattern = '',
  });

  /// Check if any danger tool was called
  bool get hasDangerAlert => toolCalls.any(
    (t) => t.name == 'detect_danger' || t.name == 'alert_danger',
  );

  /// Get effective danger info (from tools or parsed from response)
  DangerInfo get effectiveDangerInfo => parsedDangerInfo ?? DangerInfo.safe();

  /// Convert tool call to parsed result
  static ToolCallResult parseToolCall(ToolCall call) {
    return ToolCallResult(toolName: call.name, arguments: call.arguments);
  }
}

/// ULTRA-SHORT prompt for maximum speed - DeafBlind assistant
/// Target: 10-15 word response for sub-second TTS
const String _deafBlindPrompt = '''Say SAFE or DANGER, then 5 words about the scene.
Example: SAFE, indoor room with chairs.
Example: DANGER, car approaching on road.''';

/// Service for handling vision model operations using Cactus SDK
/// OPTIMIZED for DeafBlind real-time assistance
/// 
/// Key optimizations:
/// - Fast mode: Skip tool LLM for real-time responsiveness
/// - Short prompts: Faster processing
/// - Priority-based alerts: Danger first
/// - Morse code: Immediate haptic feedback
class VisionService {
  CactusLM? _visionLM;
  CactusLM? _toolLM;
  bool _isVisionInitialized = false;
  bool _isToolLMInitialized = false;
  
  /// Track last analysis to prevent spam
  DateTime? _lastAnalysisTime;
  
  /// Reusable temp file path
  String? _tempFilePath;

  bool get isInitialized => _isVisionInitialized;
  bool get isToolLMReady => _isToolLMInitialized;

  /// Initialize CactusLM instances
  void _ensureInstances() {
    _visionLM ??= CactusLM(enableToolFiltering: false);
    if (!VisionConfig.useFastMode) {
      _toolLM ??= CactusLM(enableToolFiltering: true);
    }
  }

  /// Download models with progress callback
  Future<void> downloadModel({
    required void Function(ModelDownloadProgress) onProgress,
  }) async {
    try {
      _ensureInstances();

      final models = await _visionLM!.getModels();
      final existingVision = models.where((m) => m.slug == VisionConfig.visionModel);
      
      bool visionComplete = existingVision.isNotEmpty && existingVision.first.isDownloaded;
      bool toolComplete = VisionConfig.useFastMode; // Skip if fast mode

      if (!VisionConfig.useFastMode) {
        final existingTool = models.where((m) => m.slug == VisionConfig.toolCallingModel);
        toolComplete = existingTool.isNotEmpty && existingTool.first.isDownloaded;
      }

      // Download vision model
      if (!visionComplete) {
        debugPrint('Downloading vision model: ${VisionConfig.visionModel}');
        onProgress(ModelDownloadProgress(
          progress: 0.0,
          status: 'Downloading Vision Model...',
          isComplete: false,
        ));

        await _visionLM!.downloadModel(
          model: VisionConfig.visionModel,
          downloadProcessCallback: (progress, status, isError) {
            if (isError) throw ModelDownloadException(message: status);
            final overallProgress = VisionConfig.useFastMode
                ? (progress ?? 0)
                : (progress ?? 0) * 0.5;
            onProgress(ModelDownloadProgress(
              progress: overallProgress,
              status: 'Vision: $status',
              isComplete: false,
            ));
          },
        );
        visionComplete = true;
        debugPrint('Vision model downloaded');
      } else {
        onProgress(ModelDownloadProgress(
          progress: VisionConfig.useFastMode ? 1.0 : 0.5,
          status: 'Vision Model: Ready',
          isComplete: VisionConfig.useFastMode,
        ));
      }

      // Download tool LLM (skip if fast mode)
      if (!VisionConfig.useFastMode && !toolComplete) {
        debugPrint('Downloading tool model: ${VisionConfig.toolCallingModel}');
        onProgress(ModelDownloadProgress(
          progress: 0.5,
          status: 'Downloading Tool Model...',
          isComplete: false,
        ));

        await _toolLM!.downloadModel(
          model: VisionConfig.toolCallingModel,
          downloadProcessCallback: (progress, status, isError) {
            if (isError) throw ModelDownloadException(message: status);
            onProgress(ModelDownloadProgress(
              progress: 0.5 + (progress ?? 0) * 0.5,
              status: 'Tool: $status',
              isComplete: progress != null && progress >= 1.0,
            ));
          },
        );
        debugPrint('Tool model downloaded');
      }

      onProgress(ModelDownloadProgress(
        progress: 1.0,
        status: 'Models ready',
        isComplete: true,
      ));
    } on ModelDownloadException catch (e) {
      debugPrint('Model download exception: ${e.message}');
      throw ModelDownloadException(
        message: 'Download failed. Please check your internet connection and try again.',
      );
    } catch (e) {
      debugPrint('Model download error: $e');
      throw ModelDownloadException(
        message: 'Unable to download AI models. Please check your internet connection and try again.',
      );
    }
  }

  /// Initialize models for inference
  Future<void> initializeModel() async {
    _ensureInstances();

    try {
      debugPrint('Initializing vision model...');
      await _visionLM!.initializeModel(
        params: CactusInitParams(
          model: VisionConfig.visionModel,
          contextSize: VisionConfig.contextSize,
        ),
      );
      _isVisionInitialized = true;
      debugPrint('Vision model ready');

      // Initialize tool LLM (skip if fast mode)
      if (!VisionConfig.useFastMode) {
        debugPrint('Initializing tool model...');
        await _toolLM!.initializeModel(
          params: CactusInitParams(
            model: VisionConfig.toolCallingModel,
            contextSize: VisionConfig.contextSize,
          ),
        );
        _isToolLMInitialized = true;
        debugPrint('Tool model ready');
      }

      // Pre-create temp file path
      final tempDir = await getTemporaryDirectory();
      _tempFilePath = '${tempDir.path}/astra_frame.jpg';
    } catch (e) {
      _isVisionInitialized = false;
      _isToolLMInitialized = false;
      throw VisionException(message: 'Init failed: $e');
    }
  }

  /// Analyze image for DeafBlind assistance - STREAMING
  Future<VisionAnalysisResult> analyzeImageWithTools(
    Uint8List imageBytes, {
    StreamingCallback? onStreamChunk,
  }) async {
    if (!_isVisionInitialized || _visionLM == null) {
      throw VisionException(message: 'Not initialized');
    }

    // Throttle check
    final now = DateTime.now();
    if (_lastAnalysisTime != null) {
      final elapsed = now.difference(_lastAnalysisTime!);
      if (elapsed < VisionConfig.analysisInterval) {
        throw VisionException(message: 'Throttled');
      }
    }
    _lastAnalysisTime = now;

    String tempPath = _tempFilePath ?? 
        '${(await getTemporaryDirectory()).path}/frame_${now.millisecondsSinceEpoch}.jpg';

    try {
      // Save image in isolate
      await compute(_processImageInIsolate, ImageProcessingParams(
        imageBytes: imageBytes,
        tempPath: tempPath,
      ));

      // Stream vision response
      final streamResult = await _visionLM!.generateCompletionStream(
        messages: [
          ChatMessage(
            content: _deafBlindPrompt,
            role: 'user',
            images: [tempPath],
          ),
        ],
        params: CactusCompletionParams(maxTokens: VisionConfig.visionMaxTokens),
      );

      // Stream chunks to UI immediately
      final buffer = StringBuffer();
      await for (final chunk in streamResult.stream) {
        buffer.write(chunk);
        onStreamChunk?.call(chunk, false);
      }

      final result = await streamResult.result;
      final cleanedResponse = _cleanResponse(buffer.toString());
      
      debugPrint('Vision: $cleanedResponse (${result.tokensPerSecond.toStringAsFixed(0)} tok/s)');

      // Parse danger and objects
      final dangerInfo = DangerDetector.analyzeScene(cleanedResponse);
      final objects = _extractObjects(cleanedResponse);
      final morsePattern = _generateMorseForContext(dangerInfo, objects);

      // Notify completion
      onStreamChunk?.call(cleanedResponse, true);

      // Use tool LLM if enabled
      if (!VisionConfig.useFastMode && _isToolLMInitialized && _toolLM != null) {
        return await _processWithToolLLM(
          cleanedResponse,
          dangerInfo,
          objects,
          morsePattern,
          result.tokensPerSecond,
          result.timeToFirstTokenMs.toInt(),
        );
      }

      return VisionAnalysisResult(
        response: cleanedResponse,
        toolCalls: const [],
        success: true,
        parsedDangerInfo: dangerInfo,
        detectedObjects: objects,
        tokensPerSecond: result.tokensPerSecond,
        timeToFirstTokenMs: result.timeToFirstTokenMs.toInt(),
        morsePattern: morsePattern,
      );
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (e is VisionException) rethrow;
      throw VisionException(message: 'Analysis failed: $e');
    } finally {
      // Async cleanup
      _cleanupFile(tempPath);
    }
  }

  /// Process with Tool LLM using STREAMING for fast response
  Future<VisionAnalysisResult> _processWithToolLLM(
    String description,
    DangerInfo dangerInfo,
    List<String> objects,
    String morsePattern,
    double tokensPerSecond,
    int timeToFirstTokenMs,
  ) async {
    try {
      debugPrint('Tool LLM streaming: $description');
      
      // Use streaming for tool LLM as well
      final streamResult = await _toolLM!.generateCompletionStream(
        messages: [
          ChatMessage(
            content: 'Scene: "$description". Call tools: detect_danger if hazard, speak_text with short message, vibrate_morse for main object.',
            role: 'user',
          ),
        ],
        params: CactusCompletionParams(
          maxTokens: VisionConfig.toolMaxTokens,
          tools: AstraTools.allTools,
        ),
      );

      // Stream through response
      await for (final _ in streamResult.stream) {
        // Just consume stream for speed
      }
      
      final toolResult = await streamResult.result;
      debugPrint('Tool calls: ${toolResult.toolCalls.length}');

      // Extract info from tool calls
      DangerInfo? toolDangerInfo;
      String toolMorse = morsePattern;
      
      for (final call in toolResult.toolCalls) {
        debugPrint('Tool: ${call.name} -> ${call.arguments}');
        
        if (call.name == 'detect_danger' || call.name == 'alert_danger') {
          toolDangerInfo = _parseDangerFromToolCall(call);
        }
        if (call.name == 'vibrate_morse') {
          toolMorse = _getMorseForObject(call.arguments['object_type'] ?? '');
        }
      }

      return VisionAnalysisResult(
        response: description,
        toolCalls: toolResult.toolCalls,
        success: true,
        parsedDangerInfo: toolDangerInfo ?? dangerInfo,
        detectedObjects: objects,
        tokensPerSecond: tokensPerSecond,
        timeToFirstTokenMs: timeToFirstTokenMs,
        morsePattern: toolMorse,
      );
    } catch (e) {
      debugPrint('Tool error: $e');
      return VisionAnalysisResult(
        response: description,
        toolCalls: const [],
        success: true,
        parsedDangerInfo: dangerInfo,
        detectedObjects: objects,
        tokensPerSecond: tokensPerSecond,
        timeToFirstTokenMs: timeToFirstTokenMs,
        morsePattern: morsePattern,
      );
    }
  }

  /// Parse danger info from tool call
  DangerInfo _parseDangerFromToolCall(ToolCall call) {
    final args = call.arguments;
    final type = _parseDangerType(args['danger_type'] ?? args['alert_type']);
    final level = _parseDangerLevel(args['danger_level'] ?? 'warning');
    final desc = args['description'] ?? args['message'] ?? '';
    
    return DangerInfo(
      type: type,
      level: level,
      description: desc,
      morsePattern: _getMorsePattern(type, level),
    );
  }

  /// Generate morse pattern based on context
  String _generateMorseForContext(DangerInfo dangerInfo, List<String> objects) {
    // Priority 1: Danger alerts
    if (dangerInfo.level == DangerLevel.critical) {
      return MorseCode.danger; // SOS-like pattern
    }
    if (dangerInfo.level == DangerLevel.danger) {
      return _getMorseForDangerType(dangerInfo.type);
    }
    
    // Priority 2: First detected object
    if (objects.isNotEmpty) {
      return _getMorseForObject(objects.first);
    }
    
    // Default: Safe signal
    return MorseCode.safe;
  }

  /// Get morse for danger type
  String _getMorseForDangerType(DangerType type) {
    return switch (type) {
      DangerType.vehicle => MorseCode.vehicle,
      DangerType.water => MorseCode.water,
      DangerType.road => MorseCode.road,
      DangerType.obstacle => MorseCode.obstacle,
      DangerType.general => MorseCode.danger,
      DangerType.none => MorseCode.safe,
    };
  }

  /// Get morse for object type
  String _getMorseForObject(String object) {
    final lower = object.toLowerCase();
    if (lower.contains('person') || lower.contains('people')) {
      return MorseCode.person;
    }
    if (lower.contains('car') || lower.contains('vehicle') || lower.contains('truck')) {
      return MorseCode.vehicle;
    }
    if (lower.contains('water') || lower.contains('pool')) {
      return MorseCode.water;
    }
    if (lower.contains('road') || lower.contains('street')) {
      return MorseCode.road;
    }
    if (lower.contains('stairs') || lower.contains('wall') || lower.contains('obstacle')) {
      return MorseCode.obstacle;
    }
    return MorseCode.safe;
  }

  /// Get morse pattern for danger type and level
  String _getMorsePattern(DangerType type, DangerLevel level) {
    if (level == DangerLevel.critical || level == DangerLevel.danger) {
      return MorseCode.danger;
    }
    return _getMorseForDangerType(type);
  }

  DangerType _parseDangerType(String? type) {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('vehicle') || t.contains('car') || t.contains('moving')) {
      return DangerType.vehicle;
    }
    if (t.contains('water') || t.contains('pool')) {
      return DangerType.water;
    }
    if (t.contains('road') || t.contains('street') || t.contains('crossing')) {
      return DangerType.road;
    }
    if (t.contains('obstacle') || t.contains('stairs') || t.contains('hole')) {
      return DangerType.obstacle;
    }
    return DangerType.general;
  }

  DangerLevel _parseDangerLevel(String? level) {
    final l = level?.toLowerCase() ?? '';
    if (l.contains('critical')) return DangerLevel.critical;
    if (l.contains('danger')) return DangerLevel.danger;
    if (l.contains('warning')) return DangerLevel.warning;
    if (l.contains('caution')) return DangerLevel.caution;
    return DangerLevel.safe;
  }

  /// Clean response - fast cleanup for immediate TTS
  String _cleanResponse(String response) {
    // Quick stop sequence removal
    String cleaned = response
        .replaceAll('<|im_end|>', '')
        .replaceAll('<|endoftext|>', '')
        .replaceAll('<|end|>', '')
        .replaceAll('</s>', '')
        .replaceAll('###', '')
        .trim();
    
    // Keep it short - first sentence only
    final dotIndex = cleaned.indexOf('.');
    if (dotIndex > 0 && dotIndex < 100) {
      cleaned = cleaned.substring(0, dotIndex + 1);
    }
    
    // Ensure not empty
    if (cleaned.isEmpty) {
      cleaned = 'Scene analysis in progress.';
    }
    
    return cleaned;
  }

  /// Extract objects from description
  List<String> _extractObjects(String description) {
    const objects = [
      'person', 'people', 'car', 'vehicle', 'truck', 'bus', 'motorcycle',
      'bicycle', 'tree', 'building', 'door', 'chair', 'table', 'road',
      'sidewalk', 'stairs', 'steps', 'water', 'wall', 'floor', 'window',
      'sign', 'pole', 'fence', 'traffic light', 'dog', 'cat', 'animal',
    ];
    final lower = description.toLowerCase();
    return objects.where((o) => lower.contains(o)).toList();
  }

  /// Async file cleanup
  void _cleanupFile(String path) {
    Future.microtask(() async {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    });
  }

  /// Legacy method
  Future<String> analyzeImage(Uint8List imageBytes) async {
    final result = await analyzeImageWithTools(imageBytes);
    return result.response;
  }

  /// Unload models
  void unloadModel() {
    try {
      if (_visionLM != null && _isVisionInitialized) {
        _visionLM!.unload();
        debugPrint('Vision unloaded');
      }
      if (_toolLM != null && _isToolLMInitialized) {
        _toolLM!.unload();
        debugPrint('Tool LLM unloaded');
      }
    } catch (e) {
      debugPrint('Unload error: $e');
    }
    _isVisionInitialized = false;
    _isToolLMInitialized = false;
  }

  /// Dispose service
  void dispose() {
    unloadModel();
    _visionLM = null;
    _toolLM = null;
    _tempFilePath = null;
  }

  /// Check if models downloaded
  Future<bool> isModelDownloaded() async {
    try {
      final lm = _visionLM ?? CactusLM();
      final models = await lm.getModels();
      
      final vision = models.where((m) => m.slug == VisionConfig.visionModel);
      final visionOk = vision.isNotEmpty && vision.first.isDownloaded;
      
      if (VisionConfig.useFastMode) return visionOk;
      
      final tool = models.where((m) => m.slug == VisionConfig.toolCallingModel);
      final toolOk = tool.isNotEmpty && tool.first.isDownloaded;
      
      return visionOk && toolOk;
    } catch (e) {
      return false;
    }
  }
}

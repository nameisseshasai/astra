import 'package:equatable/equatable.dart';

import '../../core/utils/danger_detector.dart';
import '../../data/services/tool_executor_service.dart';

/// Represents the result of a scene analysis from the vision model
class SceneAnalysis extends Equatable {
  final String description;
  final DangerInfo dangerInfo;
  final DateTime timestamp;
  final double? confidence;
  final List<String> detectedObjects;
  final List<String> executedTools;
  final bool usedToolCalling;

  const SceneAnalysis({
    required this.description,
    required this.dangerInfo,
    required this.timestamp,
    this.confidence,
    this.detectedObjects = const [],
    this.executedTools = const [],
    this.usedToolCalling = false,
  });

  /// Create an empty/initial scene analysis
  factory SceneAnalysis.empty() => SceneAnalysis(
    description: 'Waiting for scene analysis...',
    dangerInfo: DangerInfo.safe(),
    timestamp: DateTime.now(),
    detectedObjects: const [],
  );

  /// Create a scene analysis from tool execution result
  factory SceneAnalysis.fromToolExecution(ExecutionResult result) {
    // Use detected objects from result if available, otherwise extract from description
    final objects = result.detectedObjects.isNotEmpty
        ? result.detectedObjects
        : _extractObjects(result.sceneDescription);

    return SceneAnalysis(
      description: result.displayDescription,
      dangerInfo: result.dangerInfo,
      timestamp: DateTime.now(),
      detectedObjects: objects,
      executedTools: result.executedTools,
      usedToolCalling:
          result.executedTools.contains('response_parsed') == false,
    );
  }

  /// Create a scene analysis from vision model response (legacy)
  factory SceneAnalysis.fromVisionResponse(String response) {
    final dangerInfo = DangerDetector.analyzeScene(response);
    final objects = _extractObjects(response);

    return SceneAnalysis(
      description: response,
      dangerInfo: dangerInfo,
      timestamp: DateTime.now(),
      detectedObjects: objects,
    );
  }

  /// Extract detected objects from description
  static List<String> _extractObjects(String description) {
    // Simple extraction - can be enhanced with NLP
    final commonObjects = [
      'person',
      'people',
      'car',
      'vehicle',
      'tree',
      'building',
      'door',
      'chair',
      'table',
      'phone',
      'computer',
      'road',
      'sidewalk',
      'grass',
      'sky',
      'water',
      'wall',
      'floor',
      'window',
      'sign',
    ];

    final lowerDesc = description.toLowerCase();
    return commonObjects.where((obj) => lowerDesc.contains(obj)).toList();
  }

  bool get isDangerous =>
      dangerInfo.level != DangerLevel.safe &&
      dangerInfo.level != DangerLevel.caution;

  bool get isCritical => dangerInfo.level == DangerLevel.critical;

  @override
  List<Object?> get props => [
    description,
    dangerInfo.type,
    dangerInfo.level,
    timestamp,
    executedTools,
  ];
}

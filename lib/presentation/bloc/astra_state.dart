import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/app_state.dart';
import '../../domain/entities/scene_analysis.dart';

/// State class for Astra BLoC
class AstraState extends Equatable {
  final AppStatus status;
  final CameraController? cameraController;
  final SceneAnalysis? currentAnalysis;
  final String? errorMessage;
  final ModelDownloadProgress? downloadProgress;
  final AccessibilitySettings settings;
  final bool isAnalyzing;
  final int analysisCount;
  
  /// Streaming-related state
  final bool isStreaming;
  final String streamingText;
  final bool isProcessingFrame;

  const AstraState({
    this.status = AppStatus.initial,
    this.cameraController,
    this.currentAnalysis,
    this.errorMessage,
    this.downloadProgress,
    this.settings = const AccessibilitySettings(),
    this.isAnalyzing = false,
    this.analysisCount = 0,
    this.isStreaming = false,
    this.streamingText = '',
    this.isProcessingFrame = false,
  });

  /// Create initial state
  factory AstraState.initial() => const AstraState();

  /// Copy with method for immutability
  AstraState copyWith({
    AppStatus? status,
    CameraController? cameraController,
    SceneAnalysis? currentAnalysis,
    String? errorMessage,
    ModelDownloadProgress? downloadProgress,
    AccessibilitySettings? settings,
    bool? isAnalyzing,
    int? analysisCount,
    bool? isStreaming,
    String? streamingText,
    bool? isProcessingFrame,
    bool clearError = false,
    bool clearAnalysis = false,
    bool clearDownloadProgress = false,
    bool clearStreamingText = false,
  }) {
    return AstraState(
      status: status ?? this.status,
      cameraController: cameraController ?? this.cameraController,
      currentAnalysis: clearAnalysis
          ? null
          : (currentAnalysis ?? this.currentAnalysis),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      downloadProgress: clearDownloadProgress
          ? null
          : (downloadProgress ?? this.downloadProgress),
      settings: settings ?? this.settings,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisCount: analysisCount ?? this.analysisCount,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: clearStreamingText ? '' : (streamingText ?? this.streamingText),
      isProcessingFrame: isProcessingFrame ?? this.isProcessingFrame,
    );
  }

  /// Check if camera is ready
  bool get isCameraReady =>
      cameraController != null && cameraController!.value.isInitialized;

  /// Check if the app is ready for analysis
  bool get isReadyForAnalysis =>
      status == AppStatus.ready || status == AppStatus.analyzing;

  /// Check if there's an active danger
  bool get hasDanger => currentAnalysis?.isDangerous ?? false;

  /// Check if there's a critical danger
  bool get hasCriticalDanger => currentAnalysis?.isCritical ?? false;

  @override
  List<Object?> get props => [
    status,
    cameraController?.value.isInitialized,
    currentAnalysis,
    errorMessage,
    downloadProgress,
    settings,
    isAnalyzing,
    analysisCount,
    isStreaming,
    streamingText,
    isProcessingFrame,
  ];
}

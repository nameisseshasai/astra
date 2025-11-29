import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/tool_executor_service.dart';
import '../../di/injection.dart';
import '../../domain/entities/app_state.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../../domain/repositories/vision_repository.dart';
import '../../domain/usecases/analyze_scene_usecase.dart';
import '../../domain/usecases/provide_feedback_usecase.dart';
import 'astra_event.dart';
import 'astra_state.dart';

/// Main BLoC for the Astra accessibility app
/// Uses Cactus SDK for vision analysis with danger detection and feedback
class AstraBloc extends Bloc<AstraEvent, AstraState> {
  final VisionRepository _visionRepository;
  final CameraRepository _cameraRepository;
  final FeedbackRepository _feedbackRepository;
  final AnalyzeSceneUseCase _analyzeSceneUseCase;

  // ignore: unused_field - kept for legacy mode if needed
  final ProvideFeedbackUseCase _provideFeedbackUseCase;

  StreamSubscription? _frameSubscription;
  bool _isProcessing = false;

  AstraBloc({
    required VisionRepository visionRepository,
    required CameraRepository cameraRepository,
    required FeedbackRepository feedbackRepository,
    required AnalyzeSceneUseCase analyzeSceneUseCase,
    required ProvideFeedbackUseCase provideFeedbackUseCase,
  }) : _visionRepository = visionRepository,
       _cameraRepository = cameraRepository,
       _feedbackRepository = feedbackRepository,
       _analyzeSceneUseCase = analyzeSceneUseCase,
       _provideFeedbackUseCase = provideFeedbackUseCase,
       super(AstraState.initial()) {
    on<InitializeApp>(_onInitializeApp);
    on<DownloadModel>(_onDownloadModel);
    on<DownloadProgressUpdated>(_onDownloadProgressUpdated);
    on<InitializeModel>(_onInitializeModel);
    on<InitializeCamera>(_onInitializeCamera);
    on<StartAnalysis>(_onStartAnalysis);
    on<StopAnalysis>(_onStopAnalysis);
    on<AnalysisStarted>(_onAnalysisStarted);
    on<AnalysisCompleted>(_onAnalysisCompleted);
    on<AnalysisFailed>(_onAnalysisFailed);
    on<StreamingChunkReceived>(_onStreamingChunkReceived);
    on<UpdateSettings>(_onUpdateSettings);
    on<ToggleVoiceFeedback>(_onToggleVoiceFeedback);
    on<ToggleHapticFeedback>(_onToggleHapticFeedback);
    on<ToggleDangerAlerts>(_onToggleDangerAlerts);
    on<StopSpeech>(_onStopSpeech);
    on<ResetApp>(_onResetApp);
  }

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<AstraState> emit,
  ) async {
    emit(state.copyWith(status: AppStatus.loading, clearError: true));

    // Initialize TTS
    final ttsResult = await _feedbackRepository.initializeTTS();
    if (ttsResult.isLeft()) {
      emit(
        state.copyWith(
          status: AppStatus.error,
          errorMessage: 'Failed to initialize text-to-speech',
        ),
      );
      return;
    }

    // Update tool executor with initial settings
    _updateToolExecutorSettings(state.settings);

    // Check if model is already downloaded
    final isDownloaded = await _visionRepository.isModelDownloaded();

    if (isDownloaded) {
      add(const InitializeModel());
    } else {
      add(const DownloadModel());
    }
  }

  Future<void> _onDownloadModel(
    DownloadModel event,
    Emitter<AstraState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AppStatus.modelDownloading,
        downloadProgress: ModelDownloadProgress.initial(),
      ),
    );

    final result = await _visionRepository.downloadModel(
      onProgress: (progress) {
        // Use add() to dispatch progress update events
        add(DownloadProgressUpdated(progress));
      },
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: AppStatus.error, errorMessage: failure.message),
      ),
      (_) => add(const InitializeModel()),
    );
  }

  /// Handle download progress updates
  void _onDownloadProgressUpdated(
    DownloadProgressUpdated event,
    Emitter<AstraState> emit,
  ) {
    // Only update if still downloading
    if (state.status != AppStatus.modelDownloading) return;

    emit(state.copyWith(downloadProgress: event.progress));
    debugPrint(
      'Download: ${(event.progress.progress * 100).toStringAsFixed(1)}% - ${event.progress.status}',
    );
  }

  Future<void> _onInitializeModel(
    InitializeModel event,
    Emitter<AstraState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AppStatus.modelInitializing,
        clearDownloadProgress: true,
      ),
    );

    final result = await _visionRepository.initializeModel();

    result.fold(
      (failure) => emit(
        state.copyWith(status: AppStatus.error, errorMessage: failure.message),
      ),
      (_) => add(const InitializeCamera()),
    );
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<AstraState> emit,
  ) async {
    final result = await _cameraRepository.initializeCamera();

    result.fold(
      (failure) => emit(
        state.copyWith(status: AppStatus.error, errorMessage: failure.message),
      ),
      (controller) => emit(
        state.copyWith(status: AppStatus.ready, cameraController: controller),
      ),
    );
  }

  /// Buffer to accumulate streaming text
  final StringBuffer _streamingBuffer = StringBuffer();

  Future<void> _onStartAnalysis(
    StartAnalysis event,
    Emitter<AstraState> emit,
  ) async {
    if (!state.isReadyForAnalysis || state.isAnalyzing) return;

    emit(state.copyWith(
      status: AppStatus.analyzing,
      isAnalyzing: true,
      clearStreamingText: true,
    ));

    // Ensure tool executor has latest settings
    _updateToolExecutorSettings(state.settings);

    // Start frame capture
    await _cameraRepository.startFrameCapture();

    // Subscribe to frame stream for continuous analysis
    _frameSubscription = _cameraRepository.frameStream?.listen(
      (imageBytes) async {
        // Skip if still processing previous frame
        if (_isProcessing) {
          debugPrint('Skipping frame - still processing');
          return;
        }
        _isProcessing = true;

        try {
          // Show processing state
          add(const AnalysisStarted());

          // Clear streaming buffer
          _streamingBuffer.clear();

          // Analyze with streaming callback for real-time feedback
          final analysisResult = await _analyzeSceneUseCase(
            imageBytes,
            onStreamChunk: (chunk, isComplete) {
              if (!isComplete) {
                _streamingBuffer.write(chunk);
              }
              add(StreamingChunkReceived(
                chunk: chunk,
                partialText: _streamingBuffer.toString(),
                isComplete: isComplete,
              ));
            },
          );

          analysisResult.fold(
            (failure) {
              // Skip throttle errors silently
              if (!failure.message.contains('Throttled')) {
                add(AnalysisFailed(failure.message));
              }
            },
            (analysis) => add(AnalysisCompleted(analysis)),
          );
        } catch (e) {
          final errorMsg = e.toString();
          // Skip throttle errors - normal during continuous analysis
          if (!errorMsg.contains('Throttled')) {
            debugPrint('Analysis error: $errorMsg');
            add(AnalysisFailed(errorMsg));
          }
        } finally {
          _isProcessing = false;
        }
      },
      onError: (error) {
        debugPrint('Stream error: $error');
      },
    );
  }

  /// Handle analysis started - show loading state
  void _onAnalysisStarted(AnalysisStarted event, Emitter<AstraState> emit) {
    if (!state.isAnalyzing) return;

    emit(state.copyWith(
      isProcessingFrame: true,
      isStreaming: true,
      clearStreamingText: true,
    ));
  }

  /// Handle streaming chunks - update UI in real-time
  void _onStreamingChunkReceived(
    StreamingChunkReceived event,
    Emitter<AstraState> emit,
  ) {
    if (!state.isAnalyzing) return;

    emit(state.copyWith(
      isStreaming: !event.isComplete,
      streamingText: event.partialText,
      isProcessingFrame: !event.isComplete,
    ));
  }

  /// Handle analysis completed event
  void _onAnalysisCompleted(AnalysisCompleted event, Emitter<AstraState> emit) {
    // Only update if still analyzing
    if (!state.isAnalyzing) return;

    emit(state.copyWith(
      currentAnalysis: event.analysis,
      analysisCount: state.analysisCount + 1,
      isStreaming: false,
      isProcessingFrame: false,
      clearStreamingText: true,
    ));
  }

  /// Handle analysis failed event
  void _onAnalysisFailed(AnalysisFailed event, Emitter<AstraState> emit) {
    // Log error but continue analyzing
    debugPrint('Analysis failed: ${event.errorMessage}');
    
    emit(state.copyWith(
      isStreaming: false,
      isProcessingFrame: false,
    ));
  }

  Future<void> _onStopAnalysis(
    StopAnalysis event,
    Emitter<AstraState> emit,
  ) async {
    _frameSubscription?.cancel();
    _frameSubscription = null;
    _isProcessing = false;
    _streamingBuffer.clear();

    await _cameraRepository.stopFrameCapture();
    await _feedbackRepository.stopSpeaking();
    await _feedbackRepository.cancelVibration();

    emit(state.copyWith(
      status: AppStatus.ready,
      isAnalyzing: false,
      isStreaming: false,
      isProcessingFrame: false,
      clearAnalysis: true,
      clearStreamingText: true,
    ));
  }

  /// Update tool executor service with current settings
  void _updateToolExecutorSettings(AccessibilitySettings settings) {
    try {
      final toolExecutor = sl<ToolExecutorService>();
      toolExecutor.updateSettings(settings);
    } catch (e) {
      // Service not registered yet, will be updated later
    }
  }

  void _onUpdateSettings(UpdateSettings event, Emitter<AstraState> emit) {
    emit(state.copyWith(settings: event.settings));

    // Update tool executor with new settings
    _updateToolExecutorSettings(event.settings);

    // Apply speech settings
    _feedbackRepository.setSpeechRate(event.settings.speechRate);
    _feedbackRepository.setSpeechPitch(event.settings.speechPitch);
  }

  void _onToggleVoiceFeedback(
    ToggleVoiceFeedback event,
    Emitter<AstraState> emit,
  ) {
    final newSettings = state.settings.copyWith(
      enableVoiceFeedback: !state.settings.enableVoiceFeedback,
    );
    emit(state.copyWith(settings: newSettings));
    _updateToolExecutorSettings(newSettings);
  }

  void _onToggleHapticFeedback(
    ToggleHapticFeedback event,
    Emitter<AstraState> emit,
  ) {
    final newSettings = state.settings.copyWith(
      enableHapticFeedback: !state.settings.enableHapticFeedback,
    );
    emit(state.copyWith(settings: newSettings));
    _updateToolExecutorSettings(newSettings);
  }

  void _onToggleDangerAlerts(
    ToggleDangerAlerts event,
    Emitter<AstraState> emit,
  ) {
    final newSettings = state.settings.copyWith(
      enableDangerAlerts: !state.settings.enableDangerAlerts,
    );
    emit(state.copyWith(settings: newSettings));
    _updateToolExecutorSettings(newSettings);
  }

  Future<void> _onStopSpeech(StopSpeech event, Emitter<AstraState> emit) async {
    await _feedbackRepository.stopSpeaking();
  }

  Future<void> _onResetApp(ResetApp event, Emitter<AstraState> emit) async {
    add(const StopAnalysis());
    await _visionRepository.unloadModel();
    await _cameraRepository.dispose();

    emit(AstraState.initial());
  }

  @override
  Future<void> close() async {
    _frameSubscription?.cancel();
    _isProcessing = false;
    await _cameraRepository.dispose();
    await _visionRepository.unloadModel();
    return super.close();
  }
}

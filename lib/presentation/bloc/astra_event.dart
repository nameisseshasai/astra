import 'package:equatable/equatable.dart';

import '../../domain/entities/app_state.dart';
import '../../domain/entities/scene_analysis.dart';

/// Base event class for Astra BLoC
abstract class AstraEvent extends Equatable {
  const AstraEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the app and check for model
class InitializeApp extends AstraEvent {
  const InitializeApp();
}

/// Start downloading the vision model
class DownloadModel extends AstraEvent {
  const DownloadModel();
}

/// Initialize the vision model after download
class InitializeModel extends AstraEvent {
  const InitializeModel();
}

/// Initialize the camera
class InitializeCamera extends AstraEvent {
  const InitializeCamera();
}

/// Start the scene analysis
class StartAnalysis extends AstraEvent {
  const StartAnalysis();
}

/// Stop the scene analysis
class StopAnalysis extends AstraEvent {
  const StopAnalysis();
}

/// Analysis completed with result - triggered by frame stream
class AnalysisCompleted extends AstraEvent {
  final SceneAnalysis analysis;

  const AnalysisCompleted(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

/// Analysis failed with error
class AnalysisFailed extends AstraEvent {
  final String errorMessage;

  const AnalysisFailed(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Update settings
class UpdateSettings extends AstraEvent {
  final AccessibilitySettings settings;

  const UpdateSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// Toggle voice feedback
class ToggleVoiceFeedback extends AstraEvent {
  const ToggleVoiceFeedback();
}

/// Toggle haptic feedback
class ToggleHapticFeedback extends AstraEvent {
  const ToggleHapticFeedback();
}

/// Toggle danger alerts
class ToggleDangerAlerts extends AstraEvent {
  const ToggleDangerAlerts();
}

/// Stop current speech
class StopSpeech extends AstraEvent {
  const StopSpeech();
}

/// Reset the app state
class ResetApp extends AstraEvent {
  const ResetApp();
}

/// Update download progress - used for model downloads
class DownloadProgressUpdated extends AstraEvent {
  final ModelDownloadProgress progress;

  const DownloadProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// Streaming chunk received - for real-time text updates
class StreamingChunkReceived extends AstraEvent {
  final String chunk;
  final String partialText;
  final bool isComplete;

  const StreamingChunkReceived({
    required this.chunk,
    required this.partialText,
    required this.isComplete,
  });

  @override
  List<Object?> get props => [chunk, partialText, isComplete];
}

/// Analysis started - show loading indicator
class AnalysisStarted extends AstraEvent {
  const AnalysisStarted();
}

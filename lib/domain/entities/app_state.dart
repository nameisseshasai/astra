import 'package:equatable/equatable.dart';

/// Represents the overall application state
enum AppStatus {
  initial,
  loading,
  modelDownloading,
  modelInitializing,
  ready,
  analyzing,
  error,
}

/// Model download progress information
class ModelDownloadProgress extends Equatable {
  final double progress;
  final String status;
  final bool isComplete;

  const ModelDownloadProgress({
    required this.progress,
    required this.status,
    this.isComplete = false,
  });

  factory ModelDownloadProgress.initial() =>
      const ModelDownloadProgress(progress: 0, status: 'Starting download...');

  factory ModelDownloadProgress.complete() => const ModelDownloadProgress(
    progress: 1.0,
    status: 'Download complete',
    isComplete: true,
  );

  @override
  List<Object?> get props => [progress, status, isComplete];
}

/// Settings for the accessibility features
class AccessibilitySettings extends Equatable {
  final bool enableVoiceFeedback;
  final bool enableHapticFeedback;
  final bool enableDangerAlerts;
  final double speechRate;
  final double speechPitch;
  final int analysisIntervalSeconds;
  final bool highContrastMode;

  const AccessibilitySettings({
    this.enableVoiceFeedback = true,
    this.enableHapticFeedback = true,
    this.enableDangerAlerts = true,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.analysisIntervalSeconds = 2,
    this.highContrastMode = true,
  });

  AccessibilitySettings copyWith({
    bool? enableVoiceFeedback,
    bool? enableHapticFeedback,
    bool? enableDangerAlerts,
    double? speechRate,
    double? speechPitch,
    int? analysisIntervalSeconds,
    bool? highContrastMode,
  }) {
    return AccessibilitySettings(
      enableVoiceFeedback: enableVoiceFeedback ?? this.enableVoiceFeedback,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableDangerAlerts: enableDangerAlerts ?? this.enableDangerAlerts,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      analysisIntervalSeconds:
          analysisIntervalSeconds ?? this.analysisIntervalSeconds,
      highContrastMode: highContrastMode ?? this.highContrastMode,
    );
  }

  @override
  List<Object?> get props => [
    enableVoiceFeedback,
    enableHapticFeedback,
    enableDangerAlerts,
    speechRate,
    speechPitch,
    analysisIntervalSeconds,
    highContrastMode,
  ];
}

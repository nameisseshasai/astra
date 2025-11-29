import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Camera-related failures
class CameraFailure extends Failure {
  const CameraFailure({required super.message, super.code});
}

/// Vision model failures
class VisionFailure extends Failure {
  const VisionFailure({required super.message, super.code});
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

/// Text-to-speech failures
class TTSFailure extends Failure {
  const TTSFailure({required super.message, super.code});
}

/// Haptic feedback failures
class HapticFailure extends Failure {
  const HapticFailure({required super.message, super.code});
}

/// Model download failures
class ModelDownloadFailure extends Failure {
  const ModelDownloadFailure({required super.message, super.code});
}

/// General app failures
class AppFailure extends Failure {
  const AppFailure({required super.message, super.code});
}

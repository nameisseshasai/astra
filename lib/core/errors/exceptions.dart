/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Camera-related exceptions (renamed to avoid conflict with camera package)
class AstraCameraException extends AppException {
  const AstraCameraException({required super.message, super.code});
}

/// Vision model exceptions
class VisionException extends AppException {
  const VisionException({required super.message, super.code});
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException({required super.message, super.code});
}

/// Text-to-speech exceptions
class TTSException extends AppException {
  const TTSException({required super.message, super.code});
}

/// Haptic feedback exceptions
class HapticException extends AppException {
  const HapticException({required super.message, super.code});
}

/// Model download exceptions
class ModelDownloadException extends AppException {
  const ModelDownloadException({required super.message, super.code});
}

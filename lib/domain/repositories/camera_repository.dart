import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';

/// Repository interface for camera operations
/// Follows Interface Segregation Principle (ISP)
abstract class CameraRepository {
  /// Initialize the camera
  Future<Either<Failure, CameraController>> initializeCamera();

  /// Capture a single image
  Future<Either<Failure, Uint8List>> captureImage();

  /// Get a stream of camera frames
  Stream<Uint8List>? get frameStream;

  /// Start capturing frames
  Future<Either<Failure, void>> startFrameCapture();

  /// Stop capturing frames
  Future<void> stopFrameCapture();

  /// Dispose camera resources
  Future<void> dispose();

  /// Check if camera is initialized
  bool get isInitialized;

  /// Get the camera controller
  CameraController? get controller;
}

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/camera_repository.dart';
import '../services/camera_service.dart';

/// Implementation of CameraRepository
/// Follows Dependency Inversion Principle (DIP)
class CameraRepositoryImpl implements CameraRepository {
  final CameraService _cameraService;

  CameraRepositoryImpl(this._cameraService);

  @override
  Future<Either<Failure, CameraController>> initializeCamera() async {
    try {
      final controller = await _cameraService.initializeCamera();
      return Right(controller);
    } on AstraCameraException catch (e) {
      return Left(CameraFailure(message: e.message));
    } catch (e) {
      return Left(CameraFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> captureImage() async {
    try {
      final imageBytes = await _cameraService.captureImage();
      return Right(imageBytes);
    } on AstraCameraException catch (e) {
      return Left(CameraFailure(message: e.message));
    } catch (e) {
      return Left(CameraFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Stream<Uint8List>? get frameStream => _cameraService.frameStream;

  @override
  Future<Either<Failure, void>> startFrameCapture() async {
    try {
      await _cameraService.startFrameCapture();
      return const Right(null);
    } on AstraCameraException catch (e) {
      return Left(CameraFailure(message: e.message));
    } catch (e) {
      return Left(CameraFailure(message: 'Unknown error: $e'));
    }
  }

  @override
  Future<void> stopFrameCapture() async {
    await _cameraService.stopFrameCapture();
  }

  @override
  Future<void> dispose() async {
    await _cameraService.dispose();
  }

  @override
  bool get isInitialized => _cameraService.isInitialized;

  @override
  CameraController? get controller => _cameraService.controller;
}

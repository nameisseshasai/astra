import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// Image processing params for isolate
class _ImageProcessParams {
  final Uint8List bytes;
  final int targetWidth;
  final int quality;

  const _ImageProcessParams({
    required this.bytes,
    this.targetWidth = 384,
    this.quality = 75,
  });
}

/// Process image in isolate for performance
Future<Uint8List> _processImageIsolate(_ImageProcessParams params) async {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) throw Exception('Failed to decode');
  
  final resized = img.copyResize(decoded, width: params.targetWidth);
  final jpeg = img.encodeJpg(resized, quality: params.quality);
  return Uint8List.fromList(jpeg);
}

/// Service for handling camera operations
/// OPTIMIZED for DeafBlind real-time analysis
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  StreamController<Uint8List>? _frameStreamController;
  bool _isCapturing = false;
  Timer? _captureTimer;
  bool _isProcessingFrame = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  Stream<Uint8List>? get frameStream => _frameStreamController?.stream;

  /// Initialize the camera
  Future<CameraController> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw AstraCameraException(message: 'No cameras available on device');
      }

      // Use the back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      return _controller!;
    } on AstraCameraException {
      rethrow;
    } catch (e) {
      throw AstraCameraException(message: 'Failed to initialize camera: $e');
    }
  }

  /// Capture and process a single image (optimized for DeafBlind assistance)
  Future<Uint8List> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw AstraCameraException(message: 'Camera not initialized');
    }

    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // Process image in isolate for smooth UI
      final processed = await compute(
        _processImageIsolate,
        _ImageProcessParams(
          bytes: bytes,
          targetWidth: 384, // Smaller for faster processing
          quality: 75,
        ),
      );

      return processed;
    } on AstraCameraException {
      rethrow;
    } catch (e) {
      throw AstraCameraException(message: 'Capture failed: $e');
    }
  }

  /// Start capturing frames at optimized intervals for DeafBlind assistance
  Future<void> startFrameCapture({
    Duration? interval,
  }) async {
    if (_isCapturing) return;
    if (_controller == null || !_controller!.value.isInitialized) {
      throw AstraCameraException(message: 'Camera not initialized');
    }

    final captureInterval = interval ?? VisionConfig.analysisInterval;
    
    _frameStreamController = StreamController<Uint8List>.broadcast();
    _isCapturing = true;
    _isProcessingFrame = false;

    _captureTimer = Timer.periodic(captureInterval, (timer) async {
      if (!_isCapturing) {
        timer.cancel();
        return;
      }

      // Skip if still processing previous frame
      if (_isProcessingFrame) {
        debugPrint('Skipping frame - still processing');
        return;
      }

      _isProcessingFrame = true;
      try {
        final imageBytes = await captureImage();
        _frameStreamController?.add(imageBytes);
      } catch (e) {
        debugPrint('Frame capture error: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  /// Stop capturing frames
  Future<void> stopFrameCapture() async {
    _isCapturing = false;
    _captureTimer?.cancel();
    _captureTimer = null;
    await _frameStreamController?.close();
    _frameStreamController = null;
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    await stopFrameCapture();
    await _controller?.dispose();
    _controller = null;
  }
}

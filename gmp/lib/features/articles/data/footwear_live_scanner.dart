import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:gmp/features/articles/data/footwear_camera_input.dart';
import 'package:gmp/features/articles/data/footwear_image_validator.dart';

/// Live camera scan state shown on the upload footwear screen.
enum FootwearScanStatus {
  idle,
  scanning,
  footwearDetected,
  notFootwear,
  unavailable,
}

typedef FootwearScanStatusCallback = void Function(FootwearScanStatus status);

/// Throttled ML Kit scan of the camera preview to detect footwear before capture.
class FootwearLiveScanner {
  FootwearLiveScanner();

  static const Duration _minFrameInterval = Duration(milliseconds: 800);
  static const int _acceptStreak = 2;
  static const int _rejectStreak = 2;

  CameraController? _controller;
  FootwearScanStatusCallback? _onStatusChanged;
  ImageLabeler? _labeler;
  bool _streamActive = false;
  bool _processing = false;
  DateTime? _lastProcessedAt;
  FootwearScanStatus _status = FootwearScanStatus.idle;
  int _detectStreak = 0;
  int _rejectStreakCount = 0;
  DeviceOrientation _deviceOrientation = DeviceOrientation.portraitUp;

  FootwearScanStatus get status => _status;

  Future<void> start({
    required CameraController controller,
    required FootwearScanStatusCallback onStatusChanged,
  }) async {
    await stop();
    if (kIsWeb) {
      _emit(FootwearScanStatus.unavailable);
      return;
    }

    _controller = controller;
    _onStatusChanged = onStatusChanged;
    _labeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: FootwearImageValidator.labelThreshold,
      ),
    );

    if (!controller.value.isInitialized) return;

    _emit(FootwearScanStatus.scanning);
    try {
      await controller.startImageStream(_onCameraImage);
      _streamActive = true;
    } catch (e, st) {
      debugPrint('FootwearLiveScanner: startImageStream failed: $e\n$st');
      _emit(FootwearScanStatus.unavailable);
    }
  }

  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    _onStatusChanged = null;
    _detectStreak = 0;
    _rejectStreakCount = 0;
    _processing = false;
    _lastProcessedAt = null;

    if (_streamActive && controller != null) {
      try {
        if (controller.value.isInitialized &&
            controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (e) {
        debugPrint('FootwearLiveScanner: stopImageStream failed: $e');
      }
    }
    _streamActive = false;

    await _labeler?.close();
    _labeler = null;
    _emit(FootwearScanStatus.idle);
  }

  void updateDeviceOrientation(DeviceOrientation orientation) {
    _deviceOrientation = orientation;
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_processing || _labeler == null || _controller == null) return;

    final now = DateTime.now();
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _minFrameInterval) {
      return;
    }
    _lastProcessedAt = now;
    _processing = true;

    try {
      final input = footwearInputImageFromCamera(
        image: image,
        camera: _controller!.description,
        deviceOrientation: _deviceOrientation,
      );
      if (input == null) return;

      final labels = await _labeler!.processImage(input);
      final result = FootwearImageValidator.classifyLabels(labels);

      if (result.isFootwear) {
        _rejectStreakCount = 0;
        _detectStreak++;
        if (_detectStreak >= _acceptStreak) {
          _emit(FootwearScanStatus.footwearDetected);
        }
      } else {
        _detectStreak = 0;
        _rejectStreakCount++;
        if (_rejectStreakCount >= _rejectStreak) {
          _emit(FootwearScanStatus.notFootwear);
        } else if (_status == FootwearScanStatus.idle) {
          _emit(FootwearScanStatus.scanning);
        }
      }
    } catch (e, st) {
      debugPrint('FootwearLiveScanner: frame analysis failed: $e\n$st');
    } finally {
      _processing = false;
    }
  }

  void _emit(FootwearScanStatus next) {
    if (_status == next) return;
    _status = next;
    _onStatusChanged?.call(next);
  }
}

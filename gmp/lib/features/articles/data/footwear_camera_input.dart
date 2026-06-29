import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Builds an ML Kit [InputImage] from a live [CameraImage] frame.
InputImage? footwearInputImageFromCamera({
  required CameraImage image,
  required CameraDescription camera,
  required DeviceOrientation deviceOrientation,
}) {
  final rotation = _inputImageRotation(camera, deviceOrientation);
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);

  if (Platform.isIOS) {
    if (format != InputImageFormat.bgra8888 || image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  if (!Platform.isAndroid) return null;

  if (image.planes.length == 1 &&
      (format == null || format == InputImageFormat.nv21)) {
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  if (image.planes.length >= 3) {
    final nv21 = _yuv420ToNv21(image);
    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  return null;
}

InputImageRotation? _inputImageRotation(
  CameraDescription camera,
  DeviceOrientation orientation,
) {
  final sensorOrientation = camera.sensorOrientation;
  InputImageRotation? rotation;

  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  } else if (Platform.isAndroid) {
    var rotationCompensation = _orientations[orientation] ?? 0;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation =
          (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  }

  return rotation ?? InputImageRotation.rotation0deg;
}

const _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

Uint8List _yuv420ToNv21(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yRowStride = yPlane.bytesPerRow;
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final nv21 = Uint8List(width * height + (width * height ~/ 2));
  var offset = 0;

  for (var row = 0; row < height; row++) {
    final yRowStart = row * yRowStride;
    nv21.setRange(offset, offset + width, yPlane.bytes, yRowStart);
    offset += width;
  }

  final uvHeight = height ~/ 2;
  final uvWidth = width ~/ 2;
  for (var row = 0; row < uvHeight; row++) {
    for (var col = 0; col < uvWidth; col++) {
      final uvIndex = row * uvRowStride + col * uvPixelStride;
      nv21[offset++] = vPlane.bytes[uvIndex];
      nv21[offset++] = uPlane.bytes[uvIndex];
    }
  }

  return nv21;
}

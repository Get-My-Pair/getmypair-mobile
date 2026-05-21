import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';
import 'package:path_provider/path_provider.dart';

/// Removes image background so only the footwear subject remains (transparent PNG).
class FootwearBackgroundRemover {
  FootwearBackgroundRemover._();

  static bool _initialized = false;
  static bool _initializing = false;

  /// Max dimension sent to ONNX — lowers RAM use and reduces native crashes.
  static const int _maxProcessSide = 1024;

  static Future<void> ensureInitialized() async {
    if (_initialized || kIsWeb) return;
    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _initializing = true;
    try {
      await BackgroundRemover.instance.initializeOrt();
      _initialized = true;
    } catch (e, st) {
      debugPrint('FootwearBackgroundRemover init failed: $e\n$st');
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  /// Downscale large photos before ONNX to avoid OOM / app kill on device.
  static Future<Uint8List> _bytesForProcessing(File source) async {
    final raw = await source.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;

    final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest <= _maxProcessSide) {
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? _maxProcessSide : null,
      height: decoded.height > decoded.width ? _maxProcessSide : null,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }

  /// Returns PNG [File] with transparent background, or null to keep [source].
  static Future<File?> removeBackground(File source) async {
    if (kIsWeb) return null;

    try {
      await ensureInitialized();
      final bytes = await _bytesForProcessing(source);
      final cutout = await BackgroundRemover.instance.removeBg(
        bytes,
        threshold: 0.48,
        smoothMask: true,
        enhanceEdges: true,
      );

      try {
        final png = await _encodePng(cutout);
        if (png == null) return null;

        final dir = await getTemporaryDirectory();
        final out = File(
          '${dir.path}/footwear_cutout_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await out.writeAsBytes(png);
        return out;
      } finally {
        cutout.dispose();
      }
    } catch (e, st) {
      debugPrint('FootwearBackgroundRemover failed: $e\n$st');
      return null;
    }
  }

  static Future<Uint8List?> _encodePng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum FootwearFacing { right, left, unknown }

class FootwearOrientationResult {
  const FootwearOrientationResult({
    required this.facing,
    required this.isRightFacing,
  });

  final FootwearFacing facing;

  /// Whether the shoe's toe points to the right (the only accepted side).
  final bool isRightFacing;
}

/// Decides whether a footwear photo shows a right-side profile (toe → right).
///
/// Works best on a background-removed cutout (PNG with transparency): the
/// ankle collar — the tallest part of a shoe — belongs to the heel side, so a
/// right-facing shoe carries its upper-most mass on the LEFT half of the frame.
class FootwearOrientationDetector {
  FootwearOrientationDetector._();

  static const String wrongSideMessage =
      'Please upload a right-side profile of your footwear with the toe '
      'pointing to the right.';

  /// Alpha cutoff used to separate the shoe silhouette from the background.
  static const int _alphaThreshold = 24;

  /// Decision margin around the centre; anything inside is treated as
  /// ambiguous and is not rejected.
  static const double _margin = 0.06;

  static Future<FootwearOrientationResult> detect(File file) async {
    if (!file.existsSync()) {
      return const FootwearOrientationResult(
        facing: FootwearFacing.unknown,
        isRightFacing: true,
      );
    }
    try {
      final bytes = await file.readAsBytes();
      return await compute(_analyze, bytes);
    } catch (e) {
      debugPrint('FootwearOrientationDetector: $e');
      return const FootwearOrientationResult(
        facing: FootwearFacing.unknown,
        isRightFacing: true,
      );
    }
  }

  static FootwearOrientationResult _analyze(Uint8List bytes) {
    const unknown = FootwearOrientationResult(
      facing: FootwearFacing.unknown,
      isRightFacing: true,
    );

    final image = img.decodeImage(bytes);
    if (image == null) return unknown;

    final w = image.width;
    final h = image.height;
    if (w < 8 || h < 8) return unknown;

    final hasAlpha = image.numChannels >= 4;

    bool opaqueAt(int x, int y) {
      final p = image.getPixel(x, y);
      if (hasAlpha) return p.a > _alphaThreshold;
      // No alpha channel: assume a near-white studio background is the backdrop.
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      return lum < 235;
    }

    int minX = w, minY = h, maxX = -1, maxY = -1;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (opaqueAt(x, y)) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX <= minX || maxY <= minY) return unknown;

    final bw = maxX - minX;
    final bh = maxY - minY;

    // Upper band of the silhouette: the highest pixels (ankle collar) are
    // weighted most, so the heel side dominates the centroid.
    final topBandMaxY = minY + (bh * 0.35).round().clamp(1, bh);

    double weightedX = 0;
    double weightSum = 0;
    for (int y = minY; y < topBandMaxY; y++) {
      final rowWeight = (topBandMaxY - y).toDouble();
      for (int x = minX; x <= maxX; x++) {
        if (opaqueAt(x, y)) {
          weightedX += x * rowWeight;
          weightSum += rowWeight;
        }
      }
    }

    if (weightSum <= 0) return unknown;

    final topCx = ((weightedX / weightSum) - minX) / bw; // 0 = left, 1 = right

    if (topCx < 0.5 - _margin) {
      return const FootwearOrientationResult(
        facing: FootwearFacing.right,
        isRightFacing: true,
      );
    }
    if (topCx > 0.5 + _margin) {
      return const FootwearOrientationResult(
        facing: FootwearFacing.left,
        isRightFacing: false,
      );
    }
    return unknown;
  }
}

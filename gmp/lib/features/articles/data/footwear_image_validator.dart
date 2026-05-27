import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Result of checking whether an image likely shows footwear.
class FootwearImageValidationResult {
  const FootwearImageValidationResult._({
    required this.isFootwear,
    this.message,
    this.detectedItem,
  });

  final bool isFootwear;
  final String? message;

  /// Friendly name of what ML Kit detected (e.g. "tea cap", "coffee cup").
  final String? detectedItem;

  factory FootwearImageValidationResult.accepted() {
    return const FootwearImageValidationResult._(isFootwear: true);
  }

  factory FootwearImageValidationResult.rejected({
    String? message,
    String? detectedItem,
  }) {
    return FootwearImageValidationResult._(
      isFootwear: false,
      message: message,
      detectedItem: detectedItem,
    );
  }

  factory FootwearImageValidationResult.unavailable({String? message}) {
    return FootwearImageValidationResult._(
      isFootwear: false,
      message: message ??
          'Could not verify this image. Try again on a physical device with a clear shoe photo.',
    );
  }
}

/// On-device ML check: accept images labeled as shoes/footwear; reject others.
class FootwearImageValidator {
  FootwearImageValidator._();

  static const double _minShoeConfidence = 0.42;
  static const double _labelThreshold = 0.35;

  static const List<String> _shoeTerms = [
    'shoe',
    'shoes',
    'footwear',
    'sneaker',
    'sneakers',
    'boot',
    'boots',
    'sandal',
    'sandals',
    'slipper',
    'slippers',
    'loafer',
    'loafers',
    'heel',
    'heels',
    'trainer',
    'trainers',
    'cleat',
    'cleats',
    'oxford',
    'moccasin',
    'clog',
    'flip-flop',
    'flip flop',
    'running shoe',
    'tennis shoe',
    'athletic shoe',
    'basketball shoe',
    'hiking boot',
    'high-heeled',
  ];

  static bool _isShoeLabel(String text) {
    final lower = text.toLowerCase();
    return _shoeTerms.any((term) => lower.contains(term));
  }

  /// Maps ML Kit labels to user-friendly phrases in error copy.
  static String friendlyItemName(String rawLabel) {
    final key = rawLabel.trim().toLowerCase();
    const aliases = <String, String>{
      'coffee cup': 'coffee cup',
      'tea': 'cup of tea',
      'cup': 'cup',
      'mug': 'mug',
      'bottle': 'bottle',
      'hat': 'hat',
      'cap': 'cap',
      'baseball cap': 'baseball cap',
      'sun hat': 'hat',
      'mobile phone': 'phone',
      'cell phone': 'phone',
      'smartphone': 'phone',
      'computer': 'computer',
      'laptop': 'laptop',
      'dog': 'dog',
      'cat': 'cat',
      'person': 'person',
      'human face': 'face',
      'face': 'face',
      'selfie': 'selfie',
      'pizza': 'pizza',
      'food': 'food',
      'meal': 'meal',
      'car': 'car',
      'automobile': 'car',
      'tree': 'tree',
      'flower': 'flower',
      'book': 'book',
      'document': 'document',
      'chair': 'chair',
      'table': 'table',
      'watch': 'watch',
      'glasses': 'glasses',
      'sunglasses': 'sunglasses',
      'backpack': 'backpack',
      'handbag': 'handbag',
      'purse': 'purse',
      'toy': 'toy',
      'plant': 'plant',
      'fruit': 'fruit',
      'vegetable': 'vegetable',
      'plate': 'plate',
      'bowl': 'bowl',
      'remote': 'remote control',
      'keyboard': 'keyboard',
      'pen': 'pen',
      'scissors': 'scissors',
      'key': 'key',
      'wallet': 'wallet',
    };

    if (aliases.containsKey(key)) return aliases[key]!;
    if (key.contains('cap') && !key.contains('landscape')) return 'cap';
    if (key.contains('hat')) return 'hat';
    if (key.contains('shoe')) return 'shoe';

    return key;
  }

  /// Shown when the image is not accepted as footwear (no ML label in copy).
  static const String rejectionMessage =
      'Not a footwear image. Please upload your footwear image.';

  static String buildRejectedMessage({
    String? detectedItem,
    bool weakShoe = false,
  }) =>
      rejectionMessage;

  /// Title for the error popup (fixed; no detected-item label).
  static String dialogTitle(FootwearImageValidationResult result) {
    if (result.isFootwear) return 'Accepted';
    return 'Image not accepted';
  }

  static Future<FootwearImageValidationResult> validate(File file) async {
    if (!file.existsSync()) {
      return FootwearImageValidationResult.rejected(
        message: 'Image file not found. Please try again.',
      );
    }

    if (kIsWeb) {
      return FootwearImageValidationResult.unavailable();
    }

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: _labelThreshold),
    );

    try {
      final labels = await labeler.processImage(
        InputImage.fromFilePath(file.path),
      );

      if (labels.isEmpty) {
        return FootwearImageValidationResult.rejected(
          message: buildRejectedMessage(detectedItem: null),
        );
      }

      ImageLabel? bestShoe;
      ImageLabel? bestNonShoe;

      for (final label in labels) {
        if (_isShoeLabel(label.label)) {
          if (bestShoe == null || label.confidence > bestShoe.confidence) {
            bestShoe = label;
          }
        } else {
          if (bestNonShoe == null || label.confidence > bestNonShoe.confidence) {
            bestNonShoe = label;
          }
        }
      }

      final shoeScore = bestShoe?.confidence ?? 0.0;
      final nonShoeScore = bestNonShoe?.confidence ?? 0.0;
      final detectedRaw = bestNonShoe?.label;
      final detectedItem = detectedRaw != null
          ? friendlyItemName(detectedRaw)
          : null;

      if (shoeScore >= _minShoeConfidence && shoeScore >= nonShoeScore) {
        return FootwearImageValidationResult.accepted();
      }

      if (shoeScore > 0 && shoeScore < _minShoeConfidence) {
        return FootwearImageValidationResult.rejected(
          detectedItem: detectedItem,
          message: buildRejectedMessage(weakShoe: true),
        );
      }

      // Prefer top overall label if no strong non-shoe bucket (e.g. "Tea", "Drinkware").
      final sorted = List<ImageLabel>.from(labels)
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      final topOverall = sorted.first;
      final dynamicItem = _isShoeLabel(topOverall.label)
          ? detectedItem
          : friendlyItemName(topOverall.label);

      return FootwearImageValidationResult.rejected(
        detectedItem: dynamicItem,
        message: buildRejectedMessage(detectedItem: dynamicItem),
      );
    } catch (e, st) {
      debugPrint('FootwearImageValidator: $e\n$st');
      return FootwearImageValidationResult.unavailable();
    } finally {
      await labeler.close();
    }
  }
}

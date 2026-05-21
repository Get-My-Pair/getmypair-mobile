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

  static String _articleFor(String phrase) {
    final first = phrase.trim().isEmpty ? 'x' : phrase.trim()[0].toLowerCase();
    if ('aeiou'.contains(first)) return 'an';
    return 'a';
  }

  /// Dynamic rejection copy based on the strongest non-footwear label.
  static String buildRejectedMessage({
    String? detectedItem,
    bool weakShoe = false,
  }) {
    if (weakShoe) {
      return 'Footwear is not clear enough in this photo. Move closer and show a side profile of your shoes.';
    }

    if (detectedItem != null && detectedItem.isNotEmpty) {
      final article = _articleFor(detectedItem);
      return 'You captured $article $detectedItem. '
          'Please upload a clear side profile photo of your footwear (shoes) instead.';
    }

    return 'This image does not look like footwear. '
        'Please capture or upload a clear side profile photo of your shoes.';
  }

  static String? _dialogTitleFor(String? detectedItem) {
    if (detectedItem == null || detectedItem.isEmpty) {
      return 'Image not accepted';
    }
    final capitalized = detectedItem[0].toUpperCase() + detectedItem.substring(1);
    return 'Not footwear — looks like $capitalized';
  }

  /// Title for the error popup (short, dynamic).
  static String dialogTitle(FootwearImageValidationResult result) {
    if (result.isFootwear) return 'Accepted';
    return _dialogTitleFor(result.detectedItem) ?? 'Image not accepted';
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

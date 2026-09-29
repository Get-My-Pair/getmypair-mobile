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

  static const double _minShoeConfidence = 0.22;
  static const double _weakShoeConfidence = 0.16;
  static const double _labelThreshold = 0.22;

  /// Exposed for live camera scanning (same threshold as file validation).
  static double get labelThreshold => _labelThreshold;

  /// Footwear-related ML Kit labels, spellings, and material hints (e.g. rubber).
  static const List<String> _shoeTerms = [
    'shoe',
    'shoes',
    'footwear',
    'foot wear',
    'footware',
    'foot-wear',
    'sneaker',
    'sneakers',
    'trainer',
    'trainers',
    'running shoe',
    'running shoes',
    'tennis shoe',
    'tennis shoes',
    'athletic shoe',
    'athletic shoes',
    'basketball shoe',
    'basketball shoes',
    'sport shoe',
    'sports shoe',
    'sports shoes',
    'gym shoe',
    'gym shoes',
    'cross trainer',
    'cross-trainer',
    'boot',
    'boots',
    'hiking boot',
    'hiking boots',
    'work boot',
    'work boots',
    'ankle boot',
    'ankle boots',
    'combat boot',
    'combat boots',
    'wellington',
    'wellington boot',
    'wellingtons',
    'wellies',
    'gumboot',
    'gumboots',
    'galosh',
    'galoshes',
    'duck boot',
    'rain boot',
    'rain boots',
    'sandal',
    'sandals',
    'flip-flop',
    'flip flop',
    'flipflop',
    'flipflops',
    'flip-flops',
    'slide',
    'slides',
    'thong sandal',
    'slipper',
    'slippers',
    'house shoe',
    'house shoes',
    'bedroom slipper',
    'loafer',
    'loafers',
    'oxford',
    'oxfords',
    'derby',
    'brogue',
    'brogues',
    'moccasin',
    'moccasins',
    'monk shoe',
    'dress shoe',
    'dress shoes',
    'ballet flat',
    'ballet flats',
    'flat shoe',
    'flats',
    'heel',
    'heels',
    'high heel',
    'high heels',
    'high-heeled',
    'high-heeled shoe',
    'pump',
    'pumps',
    'stiletto',
    'stilettos',
    'wedge',
    'wedges',
    'platform shoe',
    'clog',
    'clogs',
    'espadrille',
    'espadrilles',
    'boat shoe',
    'boat shoes',
    'deck shoe',
    'cleat',
    'cleats',
    'football boot',
    'football boots',
    'soccer shoe',
    'soccer shoes',
    'golf shoe',
    'golf shoes',
    'skate shoe',
    'skate shoes',
    'crocs',
    'croc',
    'rubber',
    'rubber shoe',
    'rubber shoes',
    'rubber boot',
    'rubber boots',
    'rubber sandal',
    'rubber sandals',
    'rubber slipper',
    'rubber slippers',
    'rubber sole',
    'gumshoe',
    'chappal',
    'chappals',
    'kolhapuri',
    'jutti',
    'mule',
    'mules',
    'canvas shoe',
    'leather shoe',
    'leather boot',
    'formal shoe',
    'casual shoe',
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

  /// Shared footwear accept/reject logic for file and live camera scans.
  static FootwearImageValidationResult classifyLabels(List<ImageLabel> labels) {
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
    final detectedItem =
        detectedRaw != null ? friendlyItemName(detectedRaw) : null;

    // Accept any clear footwear signal, even if another label scores slightly higher.
    if (shoeScore >= _minShoeConfidence) {
      return FootwearImageValidationResult.accepted();
    }

    // Accept weaker footwear hits when they still appear among top labels.
    final sorted = List<ImageLabel>.from(labels)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    for (final label in sorted.take(5)) {
      if (_isShoeLabel(label.label) &&
          label.confidence >= _weakShoeConfidence) {
        return FootwearImageValidationResult.accepted();
      }
    }

    // Accept when footwear is competitive with the strongest non-footwear label.
    if (shoeScore >= _weakShoeConfidence &&
        (nonShoeScore <= 0 || shoeScore >= nonShoeScore * 0.55)) {
      return FootwearImageValidationResult.accepted();
    }

    if (shoeScore > 0 && shoeScore < _weakShoeConfidence) {
      return FootwearImageValidationResult.rejected(
        detectedItem: detectedItem,
        message: buildRejectedMessage(weakShoe: true),
      );
    }

    final topOverall = sorted.first;
    final dynamicItem = _isShoeLabel(topOverall.label)
        ? detectedItem
        : friendlyItemName(topOverall.label);

    return FootwearImageValidationResult.rejected(
      detectedItem: dynamicItem,
      message: buildRejectedMessage(detectedItem: dynamicItem),
    );
  }

  static Future<FootwearImageValidationResult> validate(File file) async {
    if (!file.existsSync()) {
      return FootwearImageValidationResult.rejected(
        message: 'Image file not found. Please try again.',
      );
    }

    // ML Kit image labeling is unavailable on web — allow upload without blocking.
    if (kIsWeb) {
      return FootwearImageValidationResult.accepted();
    }

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: _labelThreshold),
    );

    try {
      final labels = await labeler.processImage(
        InputImage.fromFilePath(file.path),
      );
      return classifyLabels(labels);
    } catch (e, st) {
      debugPrint('FootwearImageValidator: $e\n$st');
      return FootwearImageValidationResult.unavailable();
    } finally {
      await labeler.close();
    }
  }
}

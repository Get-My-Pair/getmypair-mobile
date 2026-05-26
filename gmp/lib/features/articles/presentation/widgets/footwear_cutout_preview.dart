import 'dart:io';

import 'package:flutter/material.dart';

/// Preview for footwear photos (JPEG originals or PNG cutouts).
class FootwearCutoutPreview extends StatelessWidget {
  const FootwearCutoutPreview({
    super.key,
    required this.file,
    this.height = 180,
    this.fit = BoxFit.contain,
    this.borderRadius = 12,
    this.backgroundColor = const Color(0xFF1A2E33),
  });

  final File file;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.file(
              file,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Tilt used on article rack detail and matching service UIs (Figma rack hero).
const double kArticleRackShoeTiltRadians = -0.38;

/// Network shoe photo with the same rack presentation as the article details screen.
class ArticleRackShoeImage extends StatelessWidget {
  const ArticleRackShoeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.placeholder,
    this.errorPlaceholder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? placeholder;
  final Widget? errorPlaceholder;

  @override
  Widget build(BuildContext context) {
    final emptyPh = placeholder ?? const SizedBox.shrink();
    final errPh = errorPlaceholder ?? emptyPh;
    if (imageUrl.isEmpty) {
      return _maybeBox(emptyPh);
    }

    Widget image = Image.network(
      imageUrl,
      fit: fit,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) => errPh,
    );

    image = Transform.rotate(
      angle: kArticleRackShoeTiltRadians,
      child: Transform.flip(
        flipX: true,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: image,
        ),
      ),
    );

    return _maybeBox(image);
  }

  Widget _maybeBox(Widget child) {
    if (width != null && height != null) {
      return SizedBox(width: width, height: height, child: child);
    }
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    if (height != null) {
      return SizedBox(height: height, child: child);
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return placeholder ?? const SizedBox.shrink();
        }
        return SizedBox(width: w, height: h, child: child);
      },
    );
  }
}

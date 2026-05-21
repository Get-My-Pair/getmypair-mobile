import 'dart:io';

import 'package:flutter/material.dart';

/// Preview for PNG footwear cutouts (checkerboard shows transparency).
class FootwearCutoutPreview extends StatelessWidget {
  const FootwearCutoutPreview({
    super.key,
    required this.file,
    this.height = 180,
    this.fit = BoxFit.contain,
    this.borderRadius = 12,
  });

  final File file;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  bool get _isPng => file.path.toLowerCase().endsWith('.png');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isPng)
              const CustomPaint(painter: _CheckerboardPainter())
            else
              const ColoredBox(color: Color(0xFF1A1A1A)),
            Center(
              child: Image.file(
                file,
                fit: fit,
                height: height,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  static const Color _light = Color(0xFFE0E0E0);
  static const Color _dark = Color(0xFFBDBDBD);

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 12.0;
    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        final isLight =
            ((x / tile).floor() + (y / tile).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tile, tile),
          Paint()..color = isLight ? _light : _dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

/// Pulsing placeholder used for every content-loading state.
///
/// Stays visible for the full fetch. Callers hide it only after data,
/// an empty state, or an error is ready to paint.
class AppSkeletonPulse extends StatefulWidget {
  const AppSkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<AppSkeletonPulse> createState() => _AppSkeletonPulseState();
}

class _AppSkeletonPulseState extends State<AppSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.9).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

class AppSkeletonBone extends StatelessWidget {
  const AppSkeletonBone({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 8,
    this.color = const Color(0xFFB7C9CE),
  });

  final double? width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// List-shaped skeleton: optional avatar plus two text lines per row.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.color = const Color(0xFFB7C9CE),
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
    this.showAvatar = true,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final Color color;
  final EdgeInsets padding;
  final bool showAvatar;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonPulse(
      child: ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (_, index) {
          return Row(
            children: [
              if (showAvatar) ...[
                AppSkeletonBone(
                  width: 48,
                  height: 48,
                  radius: 24,
                  color: color,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBone(
                      width: index.isEven ? 180 : 140,
                      height: 14,
                      color: color,
                    ),
                    const SizedBox(height: 8),
                    AppSkeletonBone(
                      width: double.infinity,
                      height: 10,
                      color: color.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Card stack used while a detail or form screen is loading.
class AppSkeletonCards extends StatelessWidget {
  const AppSkeletonCards({
    super.key,
    this.color = const Color(0xFFB7C9CE),
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
  });

  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonPulse(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSkeletonBone(height: 180, radius: 16, color: color),
            const SizedBox(height: 16),
            AppSkeletonBone(width: 160, height: 16, color: color),
            const SizedBox(height: 10),
            AppSkeletonBone(height: 12, color: color),
            const SizedBox(height: 8),
            AppSkeletonBone(width: 220, height: 12, color: color),
            const SizedBox(height: 20),
            AppSkeletonBone(height: 72, radius: 14, color: color),
            const SizedBox(height: 12),
            AppSkeletonBone(height: 72, radius: 14, color: color),
          ],
        ),
      ),
    );
  }
}

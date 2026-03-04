import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated gradient background that slowly shifts between colors.
/// Creates a living, breathing atmosphere for each screen.
class GradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final List<Color>? secondaryColors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    required this.colors,
    this.secondaryColors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppTheme.defaultCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColors =
        widget.secondaryColors ?? widget.colors.reversed.toList();
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin as Alignment,
              end: widget.end as Alignment,
              colors: [
                Color.lerp(
                  widget.colors[0],
                  secondaryColors[0],
                  _animation.value,
                )!,
                Color.lerp(
                  widget.colors[1],
                  secondaryColors[1],
                  _animation.value,
                )!,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

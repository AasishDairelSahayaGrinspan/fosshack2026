import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom pull-to-refresh with rotating doodle animation.
/// Wrap any scrollable content with this widget.
class DoodleRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const DoodleRefresh({super.key, required this.child, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh:
          onRefresh ??
          () async {
            await Future.delayed(const Duration(milliseconds: 800));
          },
      displacement: 50,
      color: AppColors.softIndigo,
      backgroundColor: AppColors.card(context),
      strokeWidth: 2,
      child: child,
    );
  }
}

/// Custom refresh indicator with rotating doodle — for screens that need
/// the full custom experience.
class DoodleRefreshCustom extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const DoodleRefreshCustom({super.key, required this.child, this.onRefresh});

  @override
  State<DoodleRefreshCustom> createState() => _DoodleRefreshCustomState();
}

class _DoodleRefreshCustomState extends State<DoodleRefreshCustom>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  double _pullDistance = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    _spinController.repeat();

    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    _spinController.stop();
    _spinController.reset();
    setState(() {
      _isRefreshing = false;
      _pullDistance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification &&
            notification.overscroll < 0) {
          setState(() {
            _pullDistance = (_pullDistance - notification.overscroll).clamp(
              0.0,
              100.0,
            );
          });
          if (_pullDistance >= 80 && !_isRefreshing) {
            _handleRefresh();
          }
        }
        if (notification is ScrollEndNotification && !_isRefreshing) {
          setState(() => _pullDistance = 0);
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_pullDistance > 10 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _isRefreshing ? 60 : _pullDistance.clamp(0, 80),
                alignment: Alignment.center,
                child: AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    final angle = _isRefreshing
                        ? _spinController.value * 2 * pi
                        : (_pullDistance / 80) * pi;
                    final opacity = (_pullDistance / 60).clamp(0.0, 1.0);

                    return Opacity(
                      opacity: _isRefreshing ? 1.0 : opacity,
                      child: Transform.rotate(
                        angle: angle,
                        child: Icon(
                          Icons.refresh_rounded,
                          color: AppColors.softIndigo,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int streakCount;
  final double size;

  const StreakBadge({
    super.key,
    required this.streakCount,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: streakCount > 0
            ? Colors.orange.shade100
            : Colors.grey.shade200,
        border: Border.all(
          color: streakCount > 0 ? Colors.orange : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department,
            size: size * 0.35,
            color: streakCount > 0 ? Colors.orange : Colors.grey,
          ),
          Text(
            '$streakCount',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: streakCount > 0 ? Colors.orange.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

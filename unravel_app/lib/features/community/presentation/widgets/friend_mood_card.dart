import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/friend.dart';

class FriendMoodCard extends StatelessWidget {
  final Friend friend;
  const FriendMoodCard({super.key, required this.friend});

  Color _quadrantDotColor(String? quadrant) {
    switch (quadrant) {
      case 'highEnergyPleasant':
        return AppColors.highEnergyPleasant;
      case 'highEnergyUnpleasant':
        return AppColors.highEnergyUnpleasant;
      case 'lowEnergyUnpleasant':
        return AppColors.lowEnergyUnpleasant;
      case 'lowEnergyPleasant':
        return AppColors.lowEnergyPleasant;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _quadrantDotColor(friend.currentMoodQuadrant),
          ),
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: friend.moodSharingEnabled
            ? Text(
                friend.currentMoodQuadrant != null
                    ? _quadrantLabel(friend.currentMoodQuadrant!)
                    : 'No mood logged',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                'Not sharing mood',
                style: TextStyle(color: Colors.grey.shade500),
              ),
      ),
    );
  }

  String _quadrantLabel(String quadrant) {
    switch (quadrant) {
      case 'highEnergyPleasant':
        return 'High Energy, Pleasant';
      case 'highEnergyUnpleasant':
        return 'High Energy, Unpleasant';
      case 'lowEnergyUnpleasant':
        return 'Low Energy, Unpleasant';
      case 'lowEnergyPleasant':
        return 'Low Energy, Pleasant';
      default:
        return quadrant;
    }
  }
}

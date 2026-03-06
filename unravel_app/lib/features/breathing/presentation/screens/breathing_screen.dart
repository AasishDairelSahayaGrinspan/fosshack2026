import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/breathing_exercise.dart';
import '../../domain/providers/breathing_provider.dart';
import '../../../avatar/presentation/widgets/mood_avatar.dart';

class BreathingScreen extends ConsumerWidget {
  const BreathingScreen({super.key});

  String _phaseLabel(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return 'INHALE';
      case BreathPhase.holdIn:
        return 'HOLD';
      case BreathPhase.exhale:
        return 'EXHALE';
      case BreathPhase.holdOut:
        return 'HOLD';
    }
  }

  Color _phaseColor(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return AppColors.highEnergyPleasant;
      case BreathPhase.holdIn:
        return AppColors.primary;
      case BreathPhase.exhale:
        return AppColors.lowEnergyPleasant;
      case BreathPhase.holdOut:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breathing = ref.watch(breathingProvider);
    final notifier = ref.read(breathingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Avatar as visual guide
              const MoodAvatar(size: 220),
              const SizedBox(height: 32),

              // Phase label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  breathing.isActive
                      ? _phaseLabel(breathing.currentPhase)
                      : 'Ready',
                  key: ValueKey(breathing.isActive
                      ? breathing.currentPhase
                      : 'ready'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: breathing.isActive
                            ? _phaseColor(breathing.currentPhase)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress indicator
              SizedBox(
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: breathing.isActive ? breathing.progress : 0,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: AppColors.surfaceVariant,
                  color: breathing.isActive
                      ? _phaseColor(breathing.currentPhase)
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Completed cycles
              Text(
                'Completed cycles: ${breathing.completedCycles}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              // Start/Stop button
              SizedBox(
                width: 200,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    if (breathing.isActive) {
                      notifier.stop();
                    } else {
                      notifier.start();
                    }
                  },
                  icon: Icon(
                      breathing.isActive ? Icons.stop : Icons.play_arrow),
                  label: Text(breathing.isActive ? 'Stop' : 'Start'),
                  style: FilledButton.styleFrom(
                    backgroundColor: breathing.isActive
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

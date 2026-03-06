import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mood/domain/providers/mood_provider.dart';
import '../../../breathing/domain/providers/breathing_provider.dart';

class MoodAvatar extends ConsumerStatefulWidget {
  final double size;
  const MoodAvatar({super.key, this.size = 200});
  @override
  ConsumerState<MoodAvatar> createState() => _MoodAvatarState();
}

class _MoodAvatarState extends ConsumerState<MoodAvatar> {
  StateMachineController? _stateMachine;
  SMINumber? _valenceInput;
  SMINumber? _arousalInput;
  SMINumber? _breathPhaseInput;
  SMINumber? _breathProgressInput;
  bool _riveLoaded = false;

  void _onRiveInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, 'MoodStateMachine');
    if (controller != null) {
      artboard.addController(controller);
      _stateMachine = controller;
      _valenceInput = controller.findInput<double>('valence') as SMINumber?;
      _arousalInput = controller.findInput<double>('arousal') as SMINumber?;
      _breathPhaseInput =
          controller.findInput<double>('breathPhase') as SMINumber?;
      _breathProgressInput =
          controller.findInput<double>('breathProgress') as SMINumber?;
      setState(() => _riveLoaded = true);
    }
  }

  Color _quadrantColor(String? quadrant) {
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
    final position = ref.watch(circumplexStateProvider);
    final breathing = ref.watch(breathingProvider);

    // Update Rive inputs when available
    _valenceInput?.value = position.valence;
    _arousalInput?.value = position.arousal;
    _breathPhaseInput?.value = breathing.currentPhase.index.toDouble();
    _breathProgressInput?.value = breathing.progress;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder avatar (colored circle reflecting mood)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: widget.size * 0.8,
            height: widget.size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _quadrantColor(position.selectedQuadrant).withOpacity(0.3),
              border: Border.all(
                color: _quadrantColor(position.selectedQuadrant),
                width: 3,
              ),
            ),
            child: Center(
              child: AnimatedScale(
                scale: breathing.isActive
                    ? (0.8 + breathing.progress * 0.4)
                    : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Icon(
                  Icons.face,
                  size: widget.size * 0.4,
                  color: _quadrantColor(position.selectedQuadrant),
                ),
              ),
            ),
          ),
          // Rive overlay (will show when .riv asset is available)
          // Uncomment when unravel_avatar.riv is added to assets/rive/
          // RiveAnimation.asset(
          //   'assets/rive/unravel_avatar.riv',
          //   onInit: _onRiveInit,
          //   fit: BoxFit.contain,
          // ),
        ],
      ),
    );
  }
}

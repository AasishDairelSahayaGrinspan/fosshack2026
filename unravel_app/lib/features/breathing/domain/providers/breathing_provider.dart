import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/breathing_exercise.dart';

class BreathingNotifier extends StateNotifier<BreathingState> {
  Timer? _timer;

  BreathingNotifier() : super(const BreathingState());

  void start() {
    state = state.copyWith(isActive: true, progress: 0.0, currentPhase: BreathPhase.inhale, completedCycles: 0);
    _timer = Timer.periodic(const Duration(milliseconds: 50), _tick);
  }

  void _tick(Timer timer) {
    final increment = 0.05 / state.phaseDurationSeconds; // 50ms tick
    final newProgress = state.progress + increment;

    if (newProgress >= 1.0) {
      // Advance to next phase
      final nextPhase = _nextPhase(state.currentPhase);
      final newCycles = nextPhase == BreathPhase.inhale
          ? state.completedCycles + 1
          : state.completedCycles;
      state = state.copyWith(
        currentPhase: nextPhase,
        progress: 0.0,
        completedCycles: newCycles,
      );
    } else {
      state = state.copyWith(progress: newProgress);
    }
  }

  BreathPhase _nextPhase(BreathPhase current) {
    switch (current) {
      case BreathPhase.inhale: return BreathPhase.holdIn;
      case BreathPhase.holdIn: return BreathPhase.exhale;
      case BreathPhase.exhale: return BreathPhase.holdOut;
      case BreathPhase.holdOut: return BreathPhase.inhale;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isActive: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final breathingProvider = StateNotifierProvider<BreathingNotifier, BreathingState>(
  (ref) => BreathingNotifier(),
);

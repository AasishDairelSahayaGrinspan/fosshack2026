enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingState {
  final BreathPhase currentPhase;
  final double progress;
  final int phaseDurationSeconds;
  final bool isActive;
  final int completedCycles;

  const BreathingState({
    this.currentPhase = BreathPhase.inhale,
    this.progress = 0.0,
    this.phaseDurationSeconds = 4,
    this.isActive = false,
    this.completedCycles = 0,
  });

  BreathingState copyWith({
    BreathPhase? currentPhase,
    double? progress,
    int? phaseDurationSeconds,
    bool? isActive,
    int? completedCycles,
  }) {
    return BreathingState(
      currentPhase: currentPhase ?? this.currentPhase,
      progress: progress ?? this.progress,
      phaseDurationSeconds: phaseDurationSeconds ?? this.phaseDurationSeconds,
      isActive: isActive ?? this.isActive,
      completedCycles: completedCycles ?? this.completedCycles,
    );
  }
}

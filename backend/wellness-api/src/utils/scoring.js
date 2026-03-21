export function sleepHoursToScore(sleepHours) {
  if (sleepHours >= 7 && sleepHours <= 9) return 5;
  if (sleepHours < 4 || sleepHours > 11) return 1;
  if (sleepHours < 7) {
    // Map 4..7 hours to 1..5
    return roundToOneDecimal(1 + ((sleepHours - 4) / 3) * 4);
  }
  // Map 9..11 hours down from 5..1
  return roundToOneDecimal(5 - ((sleepHours - 9) / 2) * 4);
}

export function calculateDailyWellnessScore({ mood, sleepHours, stress, energy, anxiety }) {
  // Weighted model requested by product requirements.
  const sleepScore = sleepHoursToScore(sleepHours);
  const stressInverse = 6 - stress;
  const anxietyInverse = 6 - anxiety;

  const weighted =
    mood * 0.3 +
    energy * 0.2 +
    sleepScore * 0.2 +
    stressInverse * 0.2 +
    anxietyInverse * 0.1;

  return roundToOneDecimal(clamp(weighted, 1, 5));
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function roundToOneDecimal(value) {
  return Math.round(value * 10) / 10;
}

function average(values) {
  if (!values.length) return 0;
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

export function calculateTrend(logs) {
  const sorted = [...logs].sort((a, b) => b.log_date.localeCompare(a.log_date));

  const current7 = sorted.slice(0, 7);
  const previous7 = sorted.slice(7, 14);

  const currentAverage = Number(average(current7.map((l) => l.wellness_score)).toFixed(2));
  const previousAverage = Number(average(previous7.map((l) => l.wellness_score)).toFixed(2));

  const delta = Number((currentAverage - previousAverage).toFixed(2));
  const status =
    delta > 0.2 ? 'improving' : delta < -0.2 ? 'declining' : 'stable';

  return {
    status,
    current7DayAverage: currentAverage,
    previous7DayAverage: previousAverage,
    delta,
    sampleSize: {
      current: current7.length,
      previous: previous7.length
    }
  };
}

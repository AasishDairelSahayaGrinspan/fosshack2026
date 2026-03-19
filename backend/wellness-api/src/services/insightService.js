import { calculateTrend } from './trendService.js';

export function generateInsights(logs) {
  const sorted = [...logs].sort((a, b) => b.log_date.localeCompare(a.log_date));
  const insights = [];

  addLowSleepInsight(sorted, insights);
  addHighStressInsight(sorted, insights);
  addExerciseImpactInsight(sorted, insights);
  addTrendInsight(sorted, insights);

  if (!insights.length) {
    insights.push({
      key: 'steady-routine',
      level: 'info',
      message: 'Your recent patterns look steady. Keep tracking daily to unlock deeper insights.',
      support: 'Small consistent habits can create meaningful change over time.'
    });
  }

  return insights;
}

function addLowSleepInsight(logs, insights) {
  let streak = 0;
  for (const log of logs.slice(0, 7)) {
    if (log.sleep_hours < 6) streak += 1;
    else break;
  }

  if (streak >= 3) {
    insights.push({
      key: 'low-sleep-streak',
      level: 'watch',
      message: `You logged under 6 hours of sleep for ${streak} days in a row.`,
      support: 'Try a lighter evening routine and a consistent bedtime this week.'
    });
  }
}

function addHighStressInsight(logs, insights) {
  const stressDays = logs.slice(0, 7).filter((l) => l.stress >= 4).length;
  if (stressDays >= 3) {
    insights.push({
      key: 'high-stress-frequency',
      level: 'watch',
      message: `Stress was high on ${stressDays} of the last 7 days.`,
      support: 'Consider short breathing breaks or a calming music session during busy hours.'
    });
  }
}

function addExerciseImpactInsight(logs, insights) {
  const recent = logs.slice(0, 14);
  const withExercise = recent.filter((l) => l.exercise === 1);
  const withoutExercise = recent.filter((l) => l.exercise !== 1);

  if (!withExercise.length || !withoutExercise.length) return;

  const avgWith = avg(withExercise.map((l) => l.wellness_score));
  const avgWithout = avg(withoutExercise.map((l) => l.wellness_score));

  if (avgWith - avgWithout >= 0.4) {
    insights.push({
      key: 'exercise-improvement',
      level: 'positive',
      message: 'Your wellness score tends to be higher on exercise days.',
      support: 'Keep repeating the routines that help you feel better.'
    });
  }
}

function addTrendInsight(logs, insights) {
  const trend = calculateTrend(logs);
  if (trend.sampleSize.current < 4) return;

  if (trend.status === 'improving') {
    insights.push({
      key: 'trend-improving',
      level: 'positive',
      message: 'Your 7-day trend is improving.',
      support: 'Nice work. Keep your current rhythm and review what is helping most.'
    });
  }

  if (trend.status === 'declining') {
    insights.push({
      key: 'trend-declining',
      level: 'watch',
      message: 'Your 7-day trend is dipping compared with the previous week.',
      support: 'A gentle reset can help. Start with sleep and one small stress-reduction habit.'
    });
  }
}

function avg(values) {
  if (!values.length) return 0;
  return values.reduce((s, v) => s + v, 0) / values.length;
}

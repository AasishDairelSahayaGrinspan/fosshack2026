const { Client, Databases, ID, Query } = require('node-appwrite');

const POSITIVE_WORDS = [
  'better', 'calm', 'grateful', 'hopeful', 'peaceful',
  'relaxed', 'confident', 'energized', 'good', 'happy'
];

const NEGATIVE_WORDS = [
  'worried', 'anxious', 'tired', 'stressed', 'overwhelmed',
  'sad', 'low', 'panic', 'bad', 'angry'
];

function env(name, fallback = '') {
  return process.env[name] || fallback;
}

function required(name, fallback = '') {
  const value = env(name, fallback);
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
}

function parseBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body === 'string' && req.body.trim()) {
    try { return JSON.parse(req.body); } catch (_) { return {}; }
  }
  if (req.bodyJson && typeof req.bodyJson === 'object') return req.bodyJson;
  return {};
}

function parseAction(req, body) {
  if (body.action) return String(body.action).toLowerCase();
  const path = String(req.path || '/').toLowerCase();
  if (path.includes('trend')) return 'trend';
  if (path.includes('insights')) return 'insights';
  return 'log';
}

function round1(v) {
  return Math.round(v * 10) / 10;
}

function sleepHoursToScore(sleepHours) {
  if (sleepHours >= 7 && sleepHours <= 9) return 5;
  if (sleepHours < 4 || sleepHours > 11) return 1;
  if (sleepHours < 7) return round1(1 + ((sleepHours - 4) / 3) * 4);
  return round1(5 - ((sleepHours - 9) / 2) * 4);
}

function calculateDailyWellnessScore({ mood, sleepHours, stress, energy, anxiety }) {
  const sleepScore = sleepHoursToScore(sleepHours);
  const stressInverse = 6 - stress;
  const anxietyInverse = 6 - anxiety;
  const weighted =
    mood * 0.3 +
    energy * 0.2 +
    sleepScore * 0.2 +
    stressInverse * 0.2 +
    anxietyInverse * 0.1;
  return round1(Math.min(5, Math.max(1, weighted)));
}

function scoreJournalSentiment(text) {
  if (!text || !String(text).trim()) return null;
  const words = String(text).toLowerCase().split(/[^a-z]+/).filter(Boolean);
  if (!words.length) return 0;
  const pos = words.filter((w) => POSITIVE_WORDS.includes(w)).length;
  const neg = words.filter((w) => NEGATIVE_WORDS.includes(w)).length;
  return Math.round(((pos - neg) / words.length) * 100) / 100;
}

function average(values) {
  if (!values.length) return 0;
  return values.reduce((s, v) => s + v, 0) / values.length;
}

function calculateTrend(logs) {
  const sorted = [...logs].sort((a, b) => String(b.log_date).localeCompare(String(a.log_date)));
  const current7 = sorted.slice(0, 7);
  const previous7 = sorted.slice(7, 14);
  const currentAverage = Number(average(current7.map((l) => l.wellness_score)).toFixed(2));
  const previousAverage = Number(average(previous7.map((l) => l.wellness_score)).toFixed(2));
  const delta = Number((currentAverage - previousAverage).toFixed(2));
  const status = delta > 0.2 ? 'improving' : delta < -0.2 ? 'declining' : 'stable';
  return {
    status,
    current7DayAverage: currentAverage,
    previous7DayAverage: previousAverage,
    delta,
    sampleSize: { current: current7.length, previous: previous7.length }
  };
}

function generateInsights(logs) {
  const sorted = [...logs].sort((a, b) => String(b.log_date).localeCompare(String(a.log_date)));
  const insights = [];

  let lowSleepStreak = 0;
  for (const log of sorted.slice(0, 7)) {
    if (log.sleep_hours < 6) lowSleepStreak += 1;
    else break;
  }
  if (lowSleepStreak >= 3) {
    insights.push({
      key: 'low-sleep-streak',
      level: 'watch',
      message: `You logged under 6 hours of sleep for ${lowSleepStreak} days in a row.`,
      support: 'Try a lighter evening routine and a more consistent bedtime this week.'
    });
  }

  const stressDays = sorted.slice(0, 7).filter((l) => l.stress >= 4).length;
  if (stressDays >= 3) {
    insights.push({
      key: 'high-stress-frequency',
      level: 'watch',
      message: `Stress was high on ${stressDays} of the last 7 days.`,
      support: 'Consider short breathing breaks and calming music during busy periods.'
    });
  }

  const recent = sorted.slice(0, 14);
  const withExercise = recent.filter((l) => l.exercise === 1);
  const withoutExercise = recent.filter((l) => l.exercise !== 1);
  if (withExercise.length && withoutExercise.length) {
    const avgWith = average(withExercise.map((l) => l.wellness_score));
    const avgWithout = average(withoutExercise.map((l) => l.wellness_score));
    if (avgWith - avgWithout >= 0.4) {
      insights.push({
        key: 'exercise-improvement',
        level: 'positive',
        message: 'Your wellness score tends to be higher on exercise days.',
        support: 'Keep repeating the routines that help you feel better.'
      });
    }
  }

  const trend = calculateTrend(sorted);
  if (trend.sampleSize.current >= 4) {
    if (trend.status === 'improving') {
      insights.push({
        key: 'trend-improving',
        level: 'positive',
        message: 'Your 7-day trend is improving.',
        support: 'Great momentum. Keep the habits that are helping.'
      });
    }
    if (trend.status === 'declining') {
      insights.push({
        key: 'trend-declining',
        level: 'watch',
        message: 'Your 7-day trend is dipping compared with the previous week.',
        support: 'A small reset can help. Start with sleep and one stress reduction habit.'
      });
    }
  }

  if (!insights.length) {
    insights.push({
      key: 'steady-routine',
      level: 'info',
      message: 'Your recent patterns look steady. Keep tracking daily to unlock deeper insights.',
      support: 'Small, consistent habits can create meaningful change over time.'
    });
  }

  return insights;
}

async function fetchRecentLogs(databases, databaseId, collectionId, userId, limit) {
  const result = await databases.listDocuments(databaseId, collectionId, [
    Query.equal('user_id', userId),
    Query.orderDesc('log_date'),
    Query.limit(limit)
  ]);
  return result.documents.map((d) => ({ ...d }));
}

module.exports = async ({ req, res, log, error }) => {
  try {
    const endpoint = required('APPWRITE_ENDPOINT', env('APPWRITE_FUNCTION_ENDPOINT'));
    const projectId = required('APPWRITE_PROJECT_ID', env('APPWRITE_FUNCTION_PROJECT_ID'));
    const databaseId = required('APPWRITE_DATABASE_ID');
    const collectionId = required('APPWRITE_WELLNESS_COLLECTION_ID');
    const apiKey = required('APPWRITE_API_KEY', env('APPWRITE_FUNCTION_API_KEY'));

    const client = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
    const databases = new Databases(client);

    const body = parseBody(req);
    const action = parseAction(req, body);

    if (action === 'log') {
      const userId = String(body.userId || '').trim();
      const mood = Number(body.mood);
      const sleep = Number(body.sleep);
      const stress = Number(body.stress);
      const energy = Number(body.energy);
      const anxiety = Number(body.anxiety);
      const exercise = body.exercise === undefined || body.exercise === null ? null : (body.exercise ? 1 : 0);
      const journaling = body.journaling ? String(body.journaling) : null;

      if (!userId || ![mood, sleep, stress, energy, anxiety].every(Number.isFinite)) {
        return res.json({ success: false, error: 'Invalid payload for log action.' }, 400);
      }

      const wellnessScore = calculateDailyWellnessScore({
        mood,
        sleepHours: sleep,
        stress,
        energy,
        anxiety
      });

      const docId = ID.unique();
      await databases.createDocument(databaseId, collectionId, docId, {
        user_id: userId,
        log_date: new Date().toISOString(),
        mood,
        sleep_hours: sleep,
        stress,
        energy,
        anxiety,
        exercise,
        journaling,
        journal_sentiment: scoreJournalSentiment(journaling),
        wellness_score: wellnessScore,
        created_at: new Date().toISOString()
      });

      return res.json({
        success: true,
        action: 'log',
        storedDocumentId: docId,
        wellnessScore,
        sleepScore: sleepHoursToScore(sleep),
        safeNotice: 'This score is a supportive wellness indicator and not medical advice.'
      });
    }

    if (action === 'trend') {
      const userId = String(body.userId || '').trim();
      if (!userId) return res.json({ success: false, error: 'userId is required.' }, 400);
      const logs = await fetchRecentLogs(databases, databaseId, collectionId, userId, 30);
      const trend = calculateTrend(logs);
      return res.json({
        success: true,
        action: 'trend',
        trend,
        points: logs.slice(0, 14).map((l) => ({ date: l.log_date, score: l.wellness_score }))
      });
    }

    if (action === 'insights') {
      const userId = String(body.userId || '').trim();
      if (!userId) return res.json({ success: false, error: 'userId is required.' }, 400);
      const logs = await fetchRecentLogs(databases, databaseId, collectionId, userId, 30);
      return res.json({
        success: true,
        action: 'insights',
        safeNotice: 'Insights are supportive wellness hints and not medical advice or diagnosis.',
        insights: generateInsights(logs)
      });
    }

    return res.json({ success: false, error: `Unsupported action: ${action}` }, 400);
  } catch (e) {
    error(e?.stack || String(e));
    return res.json({ success: false, error: e?.message || 'Function execution failed.' }, 500);
  }
};

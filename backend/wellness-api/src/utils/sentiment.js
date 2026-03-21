const POSITIVE_WORDS = [
  'better',
  'calm',
  'grateful',
  'hopeful',
  'peaceful',
  'relaxed',
  'confident',
  'energized',
  'good',
  'happy'
];

const NEGATIVE_WORDS = [
  'worried',
  'anxious',
  'tired',
  'stressed',
  'overwhelmed',
  'sad',
  'low',
  'panic',
  'bad',
  'angry'
];

// Lightweight non-clinical sentiment indicator in range [-1, 1].
export function scoreJournalSentiment(text) {
  if (!text || !text.trim()) return null;

  const words = text.toLowerCase().split(/[^a-z]+/).filter(Boolean);
  if (!words.length) return 0;

  const pos = words.filter((w) => POSITIVE_WORDS.includes(w)).length;
  const neg = words.filter((w) => NEGATIVE_WORDS.includes(w)).length;

  return Math.round(((pos - neg) / words.length) * 100) / 100;
}

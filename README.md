# Unravel - Mental Wellness App

> *Slow down. You're safe here.*

Unravel is a Flutter-based mental wellness companion designed to help you check in with yourself, build healthy habits, and find calm through guided breathing, journaling, mood tracking, and community support. Built with Appwrite Cloud as the backend, it offers a gentle, offline-friendly experience across Android and iOS.

## Features

### Core Wellness
- **Daily Mood Check-ins** — Track mood (Calm, Okay, Low, Anxious, Overwhelmed) with optional notes
- **Emotion Journal** — Searchable, taggable entries with prompts, streak tracking, and reminders
- **Grounding Toolkit** — 4-4-6 Breathing, Box Breathing, 5-4-3-2-1 Grounding, Body Scan
- **Personalized Practice Queue** — Context-aware recommendations based on daily needs (Focus, Calm, Release, Rest)

### Audio & Meditation
- **Guided Podcast Sessions** — Open-source meditation, breathing, sleep, and mindfulness audio
- **Curated Music Library** — Multi-language playlists with ambient soundscapes
- **Zen Ambient Audio** — Royalty-free soundscapes during breathing exercises

### Tracking & Insights
- **Insights Dashboard** — Weekly mood trends, sleep metrics, habit tracking, recovery score
- **Wellness Analytics** — Daily wellness score aggregating mood, sleep, stress, energy, anxiety
- **Sleep & Dream Tracker** — Hours logged with dream journaling
- **Activity Tracking** — Step counting, distance (GPS), calorie estimation
- **Streak System** — Multi-day engagement tracking with gentle nudges

### Community & Support
- **Community Feed** — Share posts (Achievements, Struggles, Victories) with likes and comments
- **Community Chat** — Real-time messaging with Appwrite Realtime
- **Safety Net** — Emergency hotlines (India/US/UK/International), positive scripts, trusted contacts
- **Gratitude & Wins Board** — Track micro-accomplishments by category

### Personalization
- **Custom Avatar Creator** — Layered 2D avatar with wheel-scroll selection for face, hair, eyes, mouth, accessories, clothing
- **Onboarding** — Gender, age, relationship status, wellness concerns, sleep schedule, music preferences
- **Dark/Light Theme** — Full theme support with smooth transitions

### Notifications
- 6 notification types: Mood follow-up, evening journal, streak reminder, walking check-in, community updates, breathing nudge

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.10+ (Dart) |
| Backend | Appwrite Cloud (v1.9) |
| Auth | Email/Password, Google OAuth, Anonymous |
| Database | Appwrite Databases (13 collections) |
| Storage | Appwrite Storage (4 buckets) |
| Realtime | Appwrite Realtime subscriptions |
| Audio | just_audio |
| Location | geolocator, pedometer_2 |
| Animations | flutter_animate, Lottie |
| Notifications | flutter_local_notifications |

## Architecture

- **State Management**: Singleton services + ValueNotifier/ChangeNotifier (no Redux/BLoC/Riverpod)
- **Data Layer**: Offline-first with Appwrite sync — all writes go to Appwrite first, fall back to SharedPreferences + JSON file backup
- **Service Pattern**: AppwriteService → DatabaseService → LocalDataService (3-layer)

## Database Collections

| Collection | Purpose |
|-----------|---------|
| users | User profiles, preferences, avatar config |
| mood_entries | Daily mood tracking (0-1 scale) |
| journal_entries | Emotion journal with tags and prompts |
| streaks | Consecutive check-in tracking |
| recovery_scores | Computed wellness recovery scores |
| posts | Community feed posts |
| comments | Post comments |
| sleep_entries | Sleep hours and dream logs |
| breathing_sessions | Grounding exercise sessions |
| gratitude_entries | Gratitude & wins board entries |
| activity_logs | Steps, distance, calories |
| wellness_logs | Aggregated daily analytics |
| chat_messages | Community real-time chat |

## Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Android Studio / VS Code
- Appwrite Cloud account (or self-hosted)

### Setup
1. Clone the repo
2. Run `flutter pub get`
3. Configure `lib/services/appwrite_constants.dart` with your Appwrite project details
4. Set up Appwrite collections (see Database Collections table above)
5. Enable Google OAuth in Appwrite Console
6. Run `flutter run`

## Project Structure
```
lib/
├── main.dart
├── constants/        # Lottie URLs, static data
├── models/           # AvatarConfig, CommunityModels
├── screens/          # All app screens (25+)
├── services/         # Backend services (13 singletons)
├── theme/            # AppColors, AppTheme, AppTypography, ThemeProvider
└── widgets/          # Reusable UI components (15+)
```

## License

MIT

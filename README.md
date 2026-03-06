# Unravel - Mental Well-being Application

A next-generation, privacy-centric mental well-being application built with **Flutter** and **NestJS**. Inspired by the "How We Feel" app, Unravel uses the scientifically validated **circumplex model of emotion** to help users understand, track, and regulate their emotional states.

## Architecture Overview

```
codeblue/
├── unravel_app/          # Flutter mobile frontend
│   └── lib/
│       ├── core/         # Shared constants, theme, router, services, providers
│       └── features/     # Feature-first modules
│           ├── auth/     # JWT authentication
│           ├── mood/     # Circumplex mood tracking (144 emotion words)
│           ├── avatar/   # Interactive Rive avatar
│           ├── breathing/# Box breathing exercises (4-4-4-4)
│           ├── journal/  # Daily journaling with tags
│           ├── reports/  # fl_chart data visualizations
│           ├── recovery/ # Biometric Recovery Score
│           ├── community/# Encrypted friend sharing
│           ├── settings/ # No Advice Mode toggle
│           ├── streak/   # Login streak tracking
│           ├── music/    # Spotify playlist generation
│           └── notifications/ # Local push notifications
│
└── unravel_api/          # NestJS backend
    └── src/
        ├── entities/     # TypeORM entities (PostgreSQL)
        ├── auth/         # JWT + Passport authentication
        ├── mood/         # Mood log CRUD
        ├── journal/      # Journal entry CRUD
        ├── recovery/     # Z-score Recovery Score algorithm + cron
        ├── music/        # Spotify workaround pipeline
        ├── community/    # Encrypted invite codes + friend sharing
        └── streak/       # Streak tracking
```

## Tech Stack

### Frontend (Flutter)
| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.22+ (Dart 3.4+) |
| State Management | Riverpod (compile-time safe) |
| Navigation | GoRouter with middleware |
| Animations | Rive (NOT Lottie) - state machine driven |
| Audio | just_audio (NOT audioplayers) |
| Charts | fl_chart |
| Health Data | health package (HealthKit / Health Connect) |
| Local Storage | Hive (offline-first) + SQLite |
| Notifications | flutter_local_notifications + timezone |
| Security | flutter_secure_storage + encrypt (AES-256) |

### Backend (NestJS)
| Category | Technology |
|----------|-----------|
| Framework | NestJS (strict TypeScript) |
| Database | PostgreSQL + TypeORM |
| Authentication | JWT + Passport |
| Validation | class-validator + class-transformer |
| Scheduling | @nestjs/schedule (cron jobs) |
| HTTP Client | @nestjs/axios |

## Core Features

### 1. Circumplex Mood Tracking
Based on the Yale Center for Emotional Intelligence's research, the app maps emotions across two dimensions:
- **Valence** (pleasant to unpleasant): -1.0 to 1.0
- **Arousal** (low energy to high energy): -1.0 to 1.0

Four color-coded quadrants with **144 specific emotion words** (36 per quadrant):

| Quadrant | Energy | Valence | Color | Examples |
|----------|--------|---------|-------|----------|
| Q1 | High | Pleasant | Yellow | Excited, Joyful, Euphoric |
| Q2 | High | Unpleasant | Red | Angry, Anxious, Frustrated |
| Q3 | Low | Unpleasant | Blue | Sad, Exhausted, Lonely |
| Q4 | Low | Pleasant | Green | Calm, Serene, Content |

### 2. Interactive Avatar (Rive)
- Customizable avatar with skeletal rigging
- Real-time mood morphing via Rive StateMachineController
- Serves as breathing exercise visual guide
- Inputs: `valence`, `arousal`, `breathPhase`, `breathProgress`
- Uses 1D Blend States for fluid expression transitions

### 3. "No Advice Mode" Toggle
A core philosophical pillar - users can disable all therapeutic strategy suggestions:
- GoRouter middleware intercepts routes to `/breathing` and `/music`
- When enabled, the app functions purely as an emotional repository
- Controlled via `noAdviceModeProvider` (Riverpod StateProvider)

### 4. Breathing Exercises
- Box breathing technique (4-4-4-4: inhale, hold, exhale, hold)
- Timer.periodic at 50ms resolution feeding into Rive avatar
- Avatar chest expands/contracts in sync with breathing phases
- Ambient audio via just_audio during sessions

### 5. Recovery Scoreboard (0-100)
Synthesizes biometric data from wearables using a **Z-score algorithm**:

```
Z = (X - μ) / σ    (14-day rolling window)
Score = clamp(50 + avgZ × 15, 0, 100)
```

| Metric | Source | Interpretation |
|--------|--------|---------------|
| HRV (SDNN) | HealthKit / Health Connect | Higher = better recovery |
| Resting Heart Rate | HealthKit / Health Connect | Lower = better (negated Z) |
| Sleep Quality | Deep + REM minutes | More = better recovery |

Score zones:
- **81-100**: Peak Recovery (green)
- **41-80**: Moderate Recovery (orange)
- **0-40**: Low Recovery (red)

**Note**: Uses Health Connect (NOT deprecated Google Fit API).

### 6. Mood-Synchronized Spotify Playlists
Works around Spotify's deprecated `/recommendations` and `/audio-features` endpoints (Nov 2024):

```
User Mood → Seed Artists → Last.fm getSimilar → Spotify Search → Create Playlist → Add Tracks
```

| Pipeline Stage | Method |
|---------------|--------|
| Track Discovery | Last.fm `artist.getSimilar` API |
| Track Search | Spotify `GET /v1/search` |
| Playlist Creation | Spotify `POST /v1/users/{id}/playlists` |
| Track Population | Spotify `POST /v1/playlists/{id}/tracks` |

### 7. Daily Journal (Offline-First)
- Rich text journaling with contextual tags
- Tags: sleep, caffeine, social, exercise, medication, therapy
- Hive local storage with background sync to backend
- Linked to mood entries for correlation analysis

### 8. Data Visualization (fl_chart)
- Multi-axis overlay: mood valence + Recovery Score
- Color-coded data points by mood quadrant
- Daily/weekly toggle views
- Correlation insights between behavior and mood

### 9. Community & Friends
- **Privacy-first**: AES-256-CBC encrypted invite codes
- Opt-in mood quadrant sharing only
- Journal text and biometrics are strictly firewalled
- Bidirectional trust links via temporary codes

### 10. Push Notifications
- Local scheduling via `flutter_local_notifications`
- Survives device reboots (`RECEIVE_BOOT_COMPLETED` + `ScheduledNotificationBootReceiver`)
- No server dependency for motivational reminders
- Configurable daily reminder time

### 11. Login Streaks
- Hive-based consecutive day tracking
- Current streak and longest streak calculations
- Visual badge with fire icon on home dashboard

## Getting Started

### Prerequisites
- Flutter SDK >= 3.22
- Dart >= 3.4
- Node.js >= 18
- PostgreSQL 14+
- Last.fm API key
- Spotify Developer App credentials

### Flutter App Setup

```bash
cd unravel_app

# Install dependencies
flutter pub get

# Generate Freezed models
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### NestJS Backend Setup

```bash
cd unravel_api

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your database and API credentials

# Run in development
npm run start:dev

# Build for production
npm run build
npm run start:prod
```

### Environment Variables (Backend)

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=unravel
DB_PASS=your_password
DB_NAME=unravel
JWT_SECRET=your-jwt-secret-change-in-production
LASTFM_API_KEY=your-lastfm-api-key
INVITE_SECRET_KEY=64-hex-chars-for-aes-256
INVITE_IV=32-hex-chars-for-iv
```

## Project Structure

### Flutter (Feature-First Architecture)

Each feature follows a clean architecture pattern:
```
feature/
├── data/
│   ├── repositories/     # Data access layer
│   └── datasources/      # Local (Hive) + Remote (Dio)
├── domain/
│   ├── models/           # Freezed data classes
│   └── providers/        # Riverpod state management
└── presentation/
    ├── screens/          # Full-page widgets
    └── widgets/          # Reusable components
```

### NestJS (Modular Architecture)

Each module follows NestJS conventions:
```
module/
├── module.ts             # Module definition
├── controller.ts         # REST endpoints
├── service.ts            # Business logic
└── dto/                  # Data Transfer Objects (validated)
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login, returns JWT |

### Mood
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/mood` | Log a mood entry |
| GET | `/mood` | Get mood history |
| GET | `/mood/:id` | Get single entry |

### Journal
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/journal` | Create journal entry |
| GET | `/journal` | Get all entries |
| GET | `/journal/:id` | Get single entry |

### Recovery
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/recovery/health-data` | Submit biometric data |
| GET | `/recovery/score` | Get latest Recovery Score |
| GET | `/recovery/history?days=7` | Get score history |

### Music
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/music/playlist` | Generate mood-based Spotify playlist |

### Community
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/community/invite` | Generate encrypted invite code |
| POST | `/community/accept` | Accept an invite |
| GET | `/community/friends` | Get friends list |
| GET | `/community/moods` | Get friends' shared moods |
| PATCH | `/community/:id/sharing` | Toggle mood sharing |

## Design Decisions

### Why Rive over Lottie?
Lottie animations are pre-rendered linear sequences - each avatar state would require a separate JSON file, causing exponential app bloat. Rive provides **real-time state machines** with skeletal rigging, enabling a single `.riv` file to handle all mood expressions through additive blending and 1D blend states.

### Why Riverpod over BLoC?
Riverpod offers compile-time safety, deeply integrated dependency injection, and cleaner provider composition. The `noAdviceModeProvider` seamlessly integrates with GoRouter's redirect logic, and providers like `circumplexStateProvider` can be consumed by both Rive controllers and UI widgets simultaneously.

### Why Local Notifications over FCM?
Daily motivational quotes don't need server infrastructure. `flutter_local_notifications` with `zonedSchedule` handles repeating notifications offline, reducing server costs and network dependency. The `ScheduledNotificationBootReceiver` ensures notifications persist after device reboots.

### Why the Spotify Workaround?
Spotify deprecated `GET /recommendations` and `GET /audio-features` in November 2024 for new apps. The Last.fm pipeline provides equivalent mood-based track discovery while using only Spotify's still-functional search and playlist management endpoints.

## Next Steps

- [ ] Design Rive avatar asset (`.riv` file) with MoodStateMachine
- [ ] Add ambient audio files to `assets/audio/`
- [ ] Implement Spotify OAuth 2.0 flow in Flutter
- [ ] Add end-to-end tests
- [ ] Set up CI/CD pipeline
- [ ] Configure iOS HealthKit entitlements
- [ ] Add data export functionality
- [ ] Implement dark mode theme

## License

This project is proprietary. All rights reserved.

# Unravel Wellness API

Node.js backend module for daily wellness scoring, 7-day trend analysis, and supportive insights.

Storage backend: Appwrite Database (no SQLite runtime dependency).

## Endpoints

### `POST /log`
Stores one daily log and calculates `wellnessScore` server-side.

Request body:

```json
{
  "userId": "user_123",
  "date": "2026-03-19T08:00:00.000Z",
  "mood": 4,
  "sleep": 7.5,
  "stress": 2,
  "energy": 4,
  "anxiety": 2,
  "exercise": true,
  "journaling": "Today felt calmer after a walk."
}
```

Response:

```json
{
  "message": "Log saved successfully.",
  "data": {
    "id": "...",
    "wellnessScore": 4.1,
    "sleepScore": 5
  }
}
```

### `GET /trend?userId=...`
Returns trend comparison:
- current 7-day moving average
- previous 7-day moving average
- status: `improving | declining | stable`

### `GET /insights?userId=...`
Returns supportive, non-medical insights from patterns:
- low sleep for 3+ days
- repeated high stress days
- score lift on exercise days
- trend-based encouragement

## Scoring model

Daily wellness score uses requested weights:
- mood: 30%
- energy: 20%
- sleep: 20%
- stress: 20% (inverse)
- anxiety: 10% (inverse)

Sleep conversion function maps hours to `1..5`:
- 7-9h -> 5
- <4h or >11h -> 1
- linear interpolation in between

## Safety policy

This API returns supportive wellness guidance only.
It does not provide diagnosis, treatment, or medical claims.

## Appwrite collection schema

Create collection `wellness_logs` under database `unravel_db` (or override with env vars).

Required attributes in `wellness_logs`:
- user-level daily metrics
- calculated `wellness_score`
- optional `journal_sentiment` for lightweight text signal

Recommended fields:
- `user_id` string (indexed)
- `log_date` datetime (indexed)
- `mood` integer
- `sleep_hours` double
- `stress` integer
- `energy` integer
- `anxiety` integer
- `exercise` integer (0/1)
- `journaling` string (optional)
- `journal_sentiment` double (optional)
- `wellness_score` double
- `created_at` datetime

## Environment variables

Set these before running:

```bash
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=unravel-app
APPWRITE_DATABASE_ID=unravel_db
APPWRITE_WELLNESS_COLLECTION_ID=wellness_logs
APPWRITE_API_KEY=<server_api_key>
```

Use a server key with minimum permissions to read/write only this collection.

## Run locally

```bash
cd backend/wellness-api
npm install
npm run dev
```

Server starts at `http://localhost:8787`.

## Scaling plan

1. Move SQLite to PostgreSQL with read replicas for analytics queries.
2. Add Redis cache for `/trend` and `/insights` responses.
3. Add async jobs for heavy insight generation and NLP upgrades.
4. Partition logs by `user_id` and month for high-volume retention.
5. Add API auth (JWT) and per-user rate limiting.

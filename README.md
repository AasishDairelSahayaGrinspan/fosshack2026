# Unravel 

Unravel is a community-driven mental wellness companion that blends mood tracking, guided practices, and supportive nudges to help users build sustainable habits. The repository is currently focused on planning and documenting the feature set while the implementation is bootstrapped.

## Project Status
- 🚧 The app is still in ideation and design; no mobile or backend code exists yet.
- 🗺️ This repository currently hosts planning artifacts (feature list, architecture outline, roadmap).
- 🤝 Contributors are encouraged to propose architecture plans or UX flows before writing code.

## Why Serenity?
- Makes self-care routines approachable with short, evidence-informed practices.
- Encourages reflection through an expressive journal and mood visualizations.
- Connects users with grounding techniques and verified crisis resources when they need them most.

## Feature Highlights
- **Daily Mood Check-ins** – Lightweight prompts that capture mood, energy, and stress levels with optional free-form notes.
- **Emotion Journal** – Searchable, taggable entries with streak tracking and reminders for reflective writing.
- **Personalized Practice Queue** – AI-assisted recommendations for breathing, meditation, or CBT-inspired exercises based on recent check-ins.
- **Guided Audio Sessions** – Downloadable, offline-friendly audio library with timers and background scores.
- **Grounding Toolkit** – Quick-access interventions (5-4-3-2-1 grounding, box breathing, body scan) optimized for mobile gestures.
- **Gratitude & Wins Board** – Visual board for micro-accomplishments to reinforce positive reframing.
- **Goal & Habit Loops** – SMART goal templates, habit loop builder, and gentle nudges via notifications.
- **Insights Dashboard** – Weekly trend lines, trigger detection, and personalized suggestions surfaced from aggregated mood data.
- **Safety Net** – Region-aware hotline directory, positive scripting, and contact escalation for trusted supporters.
- **Community Challenges (Opt-in)** – Privacy-conscious group challenges with anonymized leaderboards and badges.

## Architecture at a Glance
| Layer | Planned Stack |
| --- | --- |
| Mobile App | React Native + Expo, TypeScript, Reanimated 3 |
| Backend APIs | Node.js (NestJS) or Fastify, PostgreSQL (Supabase) |
| Analytics & ML | Lightweight Python microservice for trend detection, TensorFlow Lite on-device personalization |
| Auth & Sync | Supabase Auth with end-to-end encryption for journal entries |

## Getting Started
Implementation is in-flight. To participate:
1. Clone the repository: `git clone https://github.com/AasishDairelSahayaGrinspan/fosshack2026`
2. Create a feature branch: `git checkout -b feature/<your-feature>`
3. Propose architecture or UX changes via issues before large pull requests.

Once the core codebase lands, the README will include:
- Local development setup for the React Native client and Node.js services.
- Database schema migrations and seed data.
- Test suites (unit, integration, end-to-end) with coverage targets.

## Contributing
We welcome suggestions on:
- Inclusive UX writing and accessibility improvements.
- Evidence-based practice libraries (CBT, DBT, mindfulness, etc.).
- Privacy-preserving analytics approaches.

Please open an issue before submitting large PRs so we can plan the roadmap together.

## Roadmap Snapshot
- [ ] Finalize wireframes for onboarding, check-ins, and insights dashboard.
- [ ] Stand up Expo project with navigation, state management, and theming.
- [ ] Prototype journaling flow with offline persistence.
- [ ] Implement Supabase schema + mood entry APIs.
- [ ] Integrate notification service for reminders and streak nudges.
- [ ] Pilot AI-assisted recommendation microservice.

## License
This project is distributed under the MIT License. See `LICENSE` for details.

## Contact
Questions or collaboration ideas? Open an issue or reach out via GitHub Discussions once enabled.

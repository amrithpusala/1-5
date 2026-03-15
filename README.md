# 1-5

A real-time social dare app built on a synchronized number-matching mechanic — inspired by "What Are The Odds." Two users independently pick a number between 1 and 5. If the numbers match, both must complete an AI-generated dare. If not, the dare fades.

## Core Mechanic

```
User A picks a number (1–5)
User B picks a number (1–5)
  → Match? → AI generates an age-appropriate dare → both users must complete + record
  → No match? → Dare is discarded, round fades
```

## Features

- **Synchronized roll resolution** — concurrent number submissions with server-side match validation to prevent race conditions
- **AI dare generation** — dynamically generates dares scoped by difficulty tier and age-appropriateness constraints
- **Engagement-ranked video feed** — content recommendation algorithm surfaces videos based on retention signals (watch time, replays, completion rate) and interaction metrics (likes, shares, comments)
- **Video capture and upload pipeline** — native camera integration with async upload to Cloud Storage and Firestore metadata indexing
- **Real-time social layer** — live feed updates, notifications on match results, and in-app reactions

## Tech Stack

- **Frontend:** Swift, SwiftUI
- **Backend:** Firebase, Firestore, Cloud Storage
- **Auth:** Firebase Authentication
- **AI:** Server-side dare generation engine
- **Feed Algorithm:** Weighted scoring model ranking content by engagement signals

## Architecture

```
User A selects number ──┐
                        ├──→ Server validates match
User B selects number ──┘
  → Match confirmed
    → Dare generation engine produces challenge
      → Users record completion video
        → Video uploaded to Cloud Storage
          → Firestore indexes metadata (timestamp, engagement, tags)
            → Recommendation engine scores and ranks in feed
```

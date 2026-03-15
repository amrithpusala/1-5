# 1-5

A social dare platform inspired by BeReal where users roll a daily random number (1–5) to unlock AI-generated, age-appropriate dares. Features a TikTok-style video feed ranked by engagement signals.

## How It Works

1. **Daily Roll** — Each day, users roll a number between 1 and 5. The number determines the dare difficulty tier they unlock.
2. **AI-Generated Dares** — Dares are generated dynamically and tailored to be age-appropriate, creative, and shareable.
3. **Record & Share** — Users film themselves completing the dare and post it to the feed.
4. **For You Feed** — A content recommendation algorithm ranks and surfaces videos based on user retention and interaction signals (watch time, likes, shares, replays).

## Tech Stack

- **Frontend:** Swift, SwiftUI
- **Backend:** Firebase, Firestore
- **Auth:** Firebase Authentication
- **Storage:** Firebase Cloud Storage (video uploads)
- **AI:** AI-powered dare generation engine

## Key Features

- Daily random-number mechanic with tiered dare difficulty
- Content recommendation algorithm optimizing the "For You" feed by engagement signals
- Real-time social features (likes, comments, shares)
- Video recording and upload pipeline
- Age-appropriate content filtering

## Architecture

```
User rolls 1-5
  → Dare tier assigned
    → AI generates dare
      → User records video
        → Upload to Cloud Storage
          → Firestore indexes metadata
            → Recommendation engine ranks in feed
```

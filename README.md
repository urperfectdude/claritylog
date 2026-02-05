# ClarityLog

AI-powered productivity app with journaling, goal tracking, and smart reminders.

## Features

- 📓 **Smart Journaling** - Voice and text journaling with AI transcription
- 🎯 **Goal Tracking** - Set and track personal and professional goals
- 🔔 **Smart Reminders** - AI-powered reminder system with escalation
- � **AI Phone Calls** - ElevenLabs-powered voice calls for accountability
- �📊 **Progress Analytics** - Visual charts and insights
- 🔄 **Offline First** - Works offline with automatic sync
- 🤖 **AI Insights** - Personality and productivity pattern analysis
- 📱 **Social Sharing** - Generate and post content to LinkedIn/Twitter

---

## Architecture

### System Overview

```mermaid
graph TB
    subgraph "Mobile App (Flutter)"
        UI[UI Layer]
        RP[Riverpod State Management]
        Repo[Repository Layer]
        Local[Local Storage - Hive]
    end

    subgraph "Supabase BaaS"
        Auth[Auth]
        DB[(PostgreSQL)]
        Storage[Storage]
        RT[Realtime]
        Edge[Edge Functions]
    end

    subgraph "AI Services"
        OpenAI[OpenAI - Text/Analysis/Whisper STT]
        EL[ElevenLabs Agents - Voice Calls]
    end

    subgraph "Communication"
        FCM[Firebase Cloud Messaging]
    end

    subgraph "Social APIs"
        LinkedIn[LinkedIn API]
        Twitter[Twitter/X API]
    end

    UI --> RP
    RP --> Repo
    Repo --> Local
    Repo --> Auth
    Repo --> DB
    Repo --> Storage
    Repo --> RT
    
    Edge --> OpenAI
    Edge --> EL
    Edge --> LinkedIn
    Edge --> Twitter
    
    FCM --> UI
    Edge --> FCM
```

### Voice Journaling Flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant Supabase Storage
    participant Edge Function
    participant OpenAI
    participant PostgreSQL

    User->>App: Record voice journal
    App->>Supabase Storage: Upload audio file
    App->>Edge Function: Trigger transcription
    Edge Function->>OpenAI: Transcribe audio (Whisper)
    OpenAI-->>Edge Function: Text transcript
    Edge Function->>OpenAI: Analyze sentiment & extract insights
    OpenAI-->>Edge Function: Analysis results
    Edge Function->>PostgreSQL: Store journal + metadata
    Edge Function-->>App: Return processed journal
```

### Goal Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created
    Created --> Active: User activates
    Active --> InProgress: First update
    InProgress --> InProgress: Regular updates
    InProgress --> Completed: Goal achieved
    InProgress --> Overdue: Missed deadline
    Overdue --> Escalated: No response to notifications
    Escalated --> InProgress: AI call completed
    Completed --> [*]
```

### AI Call System (ElevenLabs Agents)

```mermaid
sequenceDiagram
    participant Scheduler as Supabase Cron
    participant Edge as Edge Function
    participant DB as PostgreSQL
    participant ElevenLabs as ElevenLabs Agents
    participant User

    Scheduler->>Edge: Check overdue goals (every 30 min)
    Edge->>DB: Query goals with escalation_level >= 3
    
    loop For each escalated goal
        Edge->>ElevenLabs: Trigger AI agent call
        ElevenLabs->>User: Outbound call
        User->>ElevenLabs: Voice conversation
        ElevenLabs->>Edge: Webhook with transcript
        Edge->>DB: Update goal progress
        Edge->>DB: Log call details
    end
```

### Self-Improving AI Profile

```mermaid
graph LR
    subgraph "Data Collection"
        J[Journals]
        G[Goals]
        C[Call Transcripts]
        I[Interactions]
    end

    subgraph "AI Processing"
        E[Embeddings Generation]
        V[(Vector Store - pgvector)]
        P[Pattern Recognition]
        S[Sentiment Trends]
    end

    subgraph "User Intelligence"
        UP[User Profile]
        PS[Personality Insights]
        PR[Preferences]
        BH[Behavioral Patterns]
    end

    J --> E
    G --> E
    C --> E
    I --> E
    E --> V
    V --> P
    V --> S
    P --> UP
    S --> PS
    P --> PR
    S --> BH
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter, Riverpod |
| **Backend** | Supabase (Auth, PostgreSQL, Storage, Edge Functions) |
| **Local Storage** | Hive |
| **AI - Text** | OpenAI (GPT-4, Whisper) |
| **AI - Voice** | ElevenLabs Agents Platform |
| **Push Notifications** | Firebase Cloud Messaging |
| **Social** | LinkedIn API, Twitter/X API |

---

## Getting Started

### Prerequisites

- Flutter SDK ^3.5.0
- Dart SDK ^3.5.0

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/urperfectdude/claritylog.git
   cd claritylog
   ```

2. Copy environment variables:
   ```bash
   cp .env.example .env
   ```

3. Fill in your API keys in `.env`:
   - Supabase URL and Anon Key
   - OpenAI API Key
   - ElevenLabs API Key, Voice ID, and Agent ID
   - Firebase Project ID
   - LinkedIn/Twitter credentials (optional)

4. Install dependencies:
   ```bash
   flutter pub get
   ```

5. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. Run the app:
   ```bash
   flutter run
   ```

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/       # App constants, environment config
│   ├── theme/           # Dark theme configuration
│   ├── utils/           # Utilities (network, hive, supabase)
│   └── extensions/      # Dart extensions
├── data/
│   ├── models/          # Data models (Journal, Goal, UserProfile)
│   └── repositories/    # Repository implementations
├── presentation/
│   ├── providers/       # Riverpod providers
│   ├── pages/           # Screens (auth, home, journal, goals)
│   ├── widgets/         # Reusable UI components
│   └── router/          # GoRouter configuration
└── services/
    ├── audio_service.dart    # Voice recording
    └── sync_service.dart     # Offline sync queue
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `OPENAI_API_KEY` | OpenAI API key for GPT and Whisper |
| `ELEVENLABS_API_KEY` | ElevenLabs API key |
| `ELEVENLABS_VOICE_ID` | Preferred voice for TTS |
| `ELEVENLABS_AGENT_ID` | ElevenLabs Agent ID for calls |
| `FIREBASE_PROJECT_ID` | Firebase project for push notifications |

---

## Escalation Levels

| Level | Action | Timing |
|-------|--------|--------|
| 0 | No action | - |
| 1 | Push notification | At reminder time |
| 2 | Push + In-app reminder | +2 hours after missed |
| 3 | AI phone call | +6 hours or next day AM |

---

## License

MIT License


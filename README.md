# FilmMate

A native macOS app that suggests movies available on your streaming services, built with SwiftUI.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Smart Suggestions** — Get 5 random movie suggestions filtered by genre and streaming provider
- **Streaming Providers** — Filter by Netflix, Amazon Prime, Disney+, HBO Max, and Paramount+
- **13 Genres** — Action, Adventure, Animation, Comedy, Crime, Documentary, Drama, Family, Fantasy, Horror, Romance, Sci-Fi, Thriller
- **Watchlist** — Save movies to a personal watchlist, persisted between sessions
- **Movie Details** — Each card shows poster, rating, synopsis, and genre tags
- **TMDB Integration** — Click any movie card to open its TMDB page in the browser
- **Offline Database** — Movies are downloaded once and stored locally for fast, offline filtering
- **Multi-language** — Full German and English localization with instant language switching
- **Dark / Light / System theme** — Respects your macOS appearance preference

## Screenshots

> _Add screenshots here_

## Requirements

- macOS 14.0 (Sonoma) or later
- A free [TMDB API key](https://www.themoviedb.org/settings/api)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Nasenhoben/FilmMate.git
cd FilmMate
```

### 2. Install dependencies

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project.

```bash
brew install xcodegen
xcodegen generate
```

### 3. Open in Xcode

```bash
open FilmMate.xcodeproj
```

### 4. Add your TMDB API key

1. Launch the app
2. Click **Settings** in the sidebar
3. Enter your TMDB API key and click **Validate**
4. Click **Update Database** to download the movie catalog

## Architecture

```
FilmMate/
├── Models/
│   ├── Movie.swift              # Movie model + TMDB API response types
│   ├── Genre.swift              # Genre enum with TMDB IDs, colors, emojis
│   └── StreamingProvider.swift  # Streaming provider enum
├── Services/
│   ├── TMDBService.swift        # TMDB API client (actor)
│   ├── DatabaseService.swift    # Local movie database + filtering
│   ├── WatchlistService.swift   # Watchlist persistence
│   ├── KeychainService.swift    # Secure API key storage
│   └── LanguageManager.swift    # Runtime language switching
├── ViewModels/
│   ├── MovieViewModel.swift     # Main content logic
│   └── SettingsViewModel.swift  # Settings + API key validation
└── Views/
    ├── MainView.swift           # Root layout
    ├── FilterSidebarView.swift  # Sidebar (providers, watchlist, genres)
    ├── SettingsView.swift       # Settings sheet
    └── Components/
        └── MovieGridCard.swift  # Individual movie card
```

## How It Works

1. **Database Download** — The app fetches movies from TMDB's `/discover/movie` endpoint, filtering server-side by streaming provider for the German market (`watch_region=DE`). Up to 50 pages per provider are fetched concurrently.
2. **Filtering** — AND-logic is applied: a movie must match at least one selected genre **and** be available on at least one selected provider.
3. **Suggestions** — 5 movies are picked randomly from the filtered set, avoiding duplicates across consecutive suggestions.

## AI-Generated

This project was fully created with the assistance of AI ([Claude](https://claude.ai) by Anthropic). The entire codebase — architecture, logic, UI, and tooling — was generated through an AI-assisted development session.

## License

MIT

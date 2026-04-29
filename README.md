# FilmMate

Eine native macOS-App, die Filmvorschläge basierend auf deinen Streaming-Diensten und Genre-Präferenzen liefert – gebaut mit SwiftUI.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.10-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **6 Filmvorschläge** — Zufällige Vorschläge aus der gefilterten Filmliste, in einem 3×2-Raster dargestellt
- **Streaming-Anbieter** — Filterung nach Netflix, Amazon Prime, Disney+, HBO Max und Paramount+
- **Bewertungsfilter** — Mindestbewertung: Alle / 6+ / 7+ / 8+
- **Laufzeitfilter** — < 90 min / 90–120 min / 120+
- **13 Genres** — Action, Abenteuer, Animation, Komödie, Krimi, Dokumentation, Drama, Familie, Fantasy, Horror, Romantik, Sci-Fi, Thriller
- **Film-Detailansicht** — Poster, Bewertung, Laufzeit, Regisseur, Besetzung, Genres und Streaming-Anbieter auf einen Blick
- **Laufzeit on-demand** — Fehlende Laufzeiten werden automatisch beim Anzeigen der Karte von der TMDB API nachgeladen und lokal gespeichert
- **Watchlist** — Filme speichern und zwischen Sessions erhalten
- **Offline-Datenbank** — Filme werden einmalig heruntergeladen und lokal als JSON gecacht
- **TMDB-Integration** — Filmdetails direkt auf TMDB öffnen
- **Dark Mode** — Folgt der macOS-Systemeinstellung

## Voraussetzungen

- macOS 14.0 (Sonoma) oder neuer
- Ein kostenloser [TMDB API-Key](https://www.themoviedb.org/settings/api)

## Setup

### 1. Repository klonen

```bash
git clone https://github.com/Nasenhoben/FilmMate.git
cd FilmMate
```

### 2. Xcode-Projekt generieren

Das Projekt verwendet [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
```

### 3. In Xcode öffnen

```bash
open FilmMate.xcodeproj
```

### 4. TMDB API-Key eintragen

1. App starten
2. **Einstellungen** in der Sidebar öffnen
3. TMDB API-Key eingeben und auf **Prüfen** klicken
4. **Datenbank aktualisieren** klicken – die App lädt die Filmliste herunter

## Architektur

```
Sources/FilmMate/
├── Models/
│   ├── Movie.swift              # Film-Model + TMDB API-Typen
│   ├── Genre.swift              # Genre-Enum mit TMDB-IDs, Farben, Emojis
│   ├── StreamingProvider.swift  # Streaming-Anbieter-Enum
│   └── RuntimeFilter.swift      # Laufzeit-Filter-Enum
├── Services/
│   ├── TMDBService.swift        # TMDB API-Client (Swift actor)
│   ├── DatabaseService.swift    # Lokale Filmdatenbank + Filterlogik
│   ├── WatchlistService.swift   # Watchlist-Persistenz
│   └── KeychainService.swift    # API-Key-Speicherung
├── ViewModels/
│   ├── MovieViewModel.swift     # Hauptlogik: Filter, Vorschläge
│   └── SettingsViewModel.swift  # Einstellungen + API-Key-Validierung
└── Views/
    ├── MainView.swift           # Root-Layout + Welcome/Empty-State
    ├── FilterSidebarView.swift  # Sidebar (Anbieter, Filter, Watchlist, Genres)
    ├── MovieDetailView.swift    # Film-Detailsheet
    ├── SettingsView.swift       # Einstellungen-Sheet
    └── Components/
        └── MovieGridCard.swift  # Einzelne Filmkarte im 3×2-Raster
```

## So funktioniert es

1. **Datenbank-Download** — Die App ruft `/discover/movie` von TMDB ab, gefiltert nach Streaming-Anbieter für den deutschen Markt (`watch_region=DE`). Pro Anbieter werden zwei Durchläufe gemacht:
   - 800 Filme sortiert nach Bewertung (`vote_average.desc`)
   - 200 Filme sortiert nach Erscheinungsdatum (`primary_release_date.desc`)

   So enthält die Datenbank sowohl Klassiker als auch neue Releases. Duplikate werden automatisch zusammengeführt.

2. **Filterung** — Ein Film muss alle aktiven Filter erfüllen: mindestens ein passendes Genre, mindestens ein ausgewählter Anbieter, Mindestbewertung und Laufzeit.

3. **Vorschläge** — 6 Filme werden zufällig aus der gefilterten Menge gewählt. Bereits gezeigte Filme werden in der nächsten Runde vermieden.

4. **Laufzeit** — Fehlende Laufzeiten werden beim ersten Anzeigen einer Filmkarte automatisch von der API nachgeladen und dauerhaft in der lokalen Datenbank gespeichert.

## Lizenz

MIT

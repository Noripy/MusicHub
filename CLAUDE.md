# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MusicHub — a Rails 8 app for club/festival goers to record tracks heard at events, even when the track is unidentified. The core concept: track entries can have a blank title (unidentified), and can be updated later when the song is eventually identified. Built mobile-first (390px max-width) with a dark-mode UI following a Figma design spec.

## Development Commands

### Local development (Docker — preferred)

```sh
docker compose up --build   # first run or after Gemfile changes
docker compose up           # subsequent runs → http://localhost:3000
```

Tailwind CSS watching runs automatically via the `css` service in `compose.yaml`.

### Without Docker

```sh
bin/dev   # starts web + tailwindcss:watch via Procfile.dev
```

### Database

```sh
docker compose run --rm web bin/rails db:create db:migrate
docker compose run --rm web bin/rails db:seed
```

### Tests

```sh
docker compose run --rm web bundle exec rspec           # all specs
docker compose run --rm web bundle exec rspec spec/path/to/spec.rb  # single file
```

### Linting / Security

```sh
bin/rubocop                 # Ruby style (rubocop-rails-omakase)
npm run lint:css            # CSS style (stylelint with Tailwind plugin)
bin/brakeman --no-pager     # Rails security static analysis
bin/bundler-audit           # gem vulnerability scan
bin/importmap audit         # JS dependency vulnerability scan
```

## Architecture

### Stack

- **Ruby 4.0.4 / Rails 8.1.3**
- **PostgreSQL** for primary data (via Neon in production, Docker container locally)
- **Solid Cache / Solid Queue / Solid Cable** — SQLite-backed adapters for cache, background jobs, and ActionCable (separate `*_schema.rb` files in `db/`)
- **Hotwire** (Turbo + Stimulus) via importmap — no Node build step for application JS
- **Tailwind CSS v4** via `tailwindcss-rails` — processed by the gem's embedded binary, not PostCSS
- **Propshaft** asset pipeline
- **Rails 8 built-in authentication** (planned for MVP; not yet implemented)

### Deployment

- **Render** (production web service) + **Neon** (managed PostgreSQL)
- Multi-stage `Dockerfile`: `development` target (includes Node for lint tools) and `production` target (slim, non-root, Thruster in front of Puma)
- `compose.yaml` uses the `development` target; Tailwind watch runs in a separate `css` service

### Design System (Tailwind v4)

All design tokens and component classes live in `app/assets/tailwind/application.css`.

**Color tokens** (defined in `@theme`):
- Background layers: `bg`, `surface`, `card`, `input`, `chip`
- `accent` (#8b5cff purple) — primary brand color
- Track status colors: `state-unset` (pink — unidentified tracks), `state-done` (green — identified)
- Text: `text-primary`, `text-secondary`, `text-muted`

**Component classes** (all prefixed `mh-`):
| Class | Purpose |
|---|---|
| `mh-screen` | Outer wrapper — centers to 390px, dark bg, full-height flex column |
| `mh-body` | Main content area with padding and scroll |
| `mh-btn-primary` / `mh-btn-secondary` | Full-width action buttons |
| `mh-card` | Track/event card with border and bg-card |
| `mh-chip-*` | Status/tag badges (`default`, `selected`, `unset`, `done`) |
| `mh-field` / `mh-label` / `mh-input` | Form field components |
| `mh-subhead` | Section header with back-arrow pattern |
| `mh-link` | Accent-colored inline link |

Font: **Inter** (loaded from Google Fonts, declared in `@theme` as `--font-sans`).

### Planned Data Models (MVP)

- **Event** — concert/club event (date, venue, event name, DJ name)
- **TrackEntry** — belongs to Event; title is nullable (unidentified state); fields include genre, mood, estimated BPM, memo

### CI (GitHub Actions)

`.github/workflows/ci.yml` runs on PR and push to `main`:
1. `brakeman` — Rails security scan
2. `bundler-audit` — gem CVE scan
3. `importmap audit` — JS CVE scan
4. `rubocop -f github` — style lint

All four must pass before merging.

# Wordstake

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/readme-card-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="assets/readme-card-light.svg">
  <img alt="Wordstake — eight tries and only match counts" src="assets/readme-card-light.svg" width="100%">
</picture>

I built Wordstake because I wanted to make something that wasn't about ecommerce or dashboards. It's a word game where you get eight tries to guess a five-letter word, using match counts instead of being shown each matching letter's position.

[Play Wordstake](https://word-stake.com/)

## How it works

The game has a daily puzzle and a practice mode, along with hints, an optional easy mode, and shareable results. Account features include saved results, stats, and a leaderboard.

## What's in the repository

- `index.html` — the game interface and JavaScript logic.
- `words.js` — word lists used by the game.
- `styles.css` and `theme.css` — styling.
- `supabase/` — SQL for anonymous results and daily comparisons.
- `privacy.html` and `terms.html` — the site's policy pages.

The frontend is plain HTML, CSS, and JavaScript. It loads Supabase's browser client from a CDN and uses Supabase for account and shared game features. Some local preferences and game state are stored in the browser.

## Running a local copy

Serve this folder with a local HTTP server. For example, if you have Python installed:

```bash
python -m http.server 8000
```

Then open [localhost:8000](http://localhost:8000). There is no package-install or build step.

The checked-in page points to the live Supabase project. Before testing account creation or result submissions, configure your copy of `index.html` to use your own backend. The SQL files here cover only part of the backend; account tables, RPC functions, and the `username-login` function also need to exist for all features to work.

The Supabase anonymous key in the browser is public configuration. Database policies and function permissions must enforce access; never replace it with a server secret. The page also includes Google Analytics and Vercel Analytics, so review those settings when hosting your own copy.


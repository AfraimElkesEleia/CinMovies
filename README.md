# CinMovies

CinMovies is a Flutter learning project that uses TMDB for its movie catalog,
Gemini for the movie assistant, Supabase for account data, and Hive for local
caching.

## Setup

Copy `.env.example` to `.env` and add:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `TMDB_API_KEY` (TMDB v4 read access token)
- `GEMINI_API_KEY`
- `GEMINI_MODEL` (optional; defaults to `gemini-3.5-flash-lite`)

Then run:

```shell
flutter pub get
flutter run
```

The `.env` file is ignored by Git. However, Flutter bundles declared assets
inside the application, so these keys are not secret in a compiled build. This
direct-client setup is intentionally suitable only for learning and local
development. Move Gemini and TMDB calls behind a secure backend before
publishing the app.

## Movie chat storage

- Guest conversations are stored only in Hive under the `guest` namespace.
- Authenticated conversations are stored in Supabase and cached in Hive under
  `user:<Supabase user ID>`.
- Guest history is not automatically transferred into an account.
- Gemini and TMDB are called directly from Flutter; no Edge Function deployment
  is required.

The SQL migrations in `supabase/migrations` contain the chat-history RLS
policies and the transactional `persist_movie_chat_exchange` function. Apply
them with the Supabase dashboard SQL editor or CLI when setting up a new
project.

## Validation

```shell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

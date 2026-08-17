# CinMovies

<p align="center">
  <img src="assets/images/app_logo.png" alt="CinMovies logo" width="150" />
</p>

CinMovies is a full-featured Flutter movie discovery application. It combines
TMDB catalog data, Supabase authentication and account storage, a Gemini-powered
movie assistant, and Hive-based local caching in one responsive, feature-first
codebase.

<p align="center">
<img width="300" alt="small reecording about cinmovies application" src="https://github.com/user-attachments/assets/fe2592a9-3191-409c-bf56-98eadfae962d" />
</p>

Users can create an account or continue as a guest. Both modes can discover
movies, search, open detailed movie pages, watch trailers, and use the AI movie
assistant. Signed-in users additionally receive cloud-backed profiles,
personalized genre recommendations, favorites, a watchlist, community reviews,
review replies, and reactions.

> This repository is a learning project. TMDB and Gemini are called directly
> from Flutter, so their credentials are included in the compiled application.
> Put those calls behind a trusted backend before releasing a production app.

## Contents

- [Core features](#core-features)
- [Account and guest behavior](#account-and-guest-behavior)
- [Trailer history and recursive cache flush](#trailer-history-and-recursive-cache-flush)
- [Gemini AI movie assistant](#gemini-ai-movie-assistant)
- [Architecture](#architecture)
- [Data sources and caching](#data-sources-and-caching)
- [Supabase data model](#supabase-data-model)
- [Packages](#packages)
- [Getting started](#getting-started)
- [Project structure](#project-structure)

## Core features

### Onboarding and personalization

- Three-page first-launch onboarding experience.
- Favorite-genre selection with a minimum of three genres.
- Favorite genres are cached per account in Hive and synchronized with
  Supabase.
- The **For You** section listens for locally cached genre changes and refreshes
  personalized TMDB results automatically.
- Onboarding and guest-mode flags are persisted with SharedPreferences so the
  correct initial route can be restored on the next launch.
<p align="center">
<img width="28%" alt="Screenshot_1786207341" src="https://github.com/user-attachments/assets/45f4c176-6cc7-491f-b9db-bb866b8482de" style="margin-right: 15px;" />
<img width="28%" height="2400" alt="Screenshot_1786207338" src="https://github.com/user-attachments/assets/a03820f5-2d81-44a1-b3a7-d991b9b4739b" style="margin-right: 15px;" />
<img width="28%" height="2400" alt="Screenshot_1786207343" src="https://github.com/user-attachments/assets/6cc55944-f262-4f2b-9879-e6b8abdefe91" style="margin-right: 15px;" />
</p>

### Authentication and guest access

- Email and password sign-in through Supabase Auth.
- Account registration with full name, password validation, and terms
  acceptance.
- Optional JPG/PNG profile photo during registration, limited to 5 MB.
- Profile images are uploaded to the Supabase `avatars` storage bucket.
- A clearly available **Continue as Guest** path requires no account.
- Logout, password update, and switching from guest mode to sign-in or
  registration are supported.
- Startup routing distinguishes first launch, signed-out, guest, and
  authenticated sessions.

### Home

- Popular movies displayed as a featured carousel.
- **Trending Now** and **New Releases** sections from TMDB.
- Personalized **For You** recommendations based on favorite genre IDs.
- “See all” pages with pagination, local text filtering, and sorting by rating,
  title, or newest release.
- Cache-first rendering: a saved home feed can be displayed immediately while
  a fresh network request runs in the background.
- Shimmer loading states, refresh indicators, saved-data notices, and retry
  behavior.

### Browse and search

- Browse TMDB movies by dynamically loaded genre.
- Popularity-based movie grid with pull-to-refresh and infinite pagination.
- Fallback genre chips when the genre request is unavailable.
- Debounced movie search with a 400 ms delay.
- Protection against stale search responses through request tokens.
- Search result pagination and sorting by rating, title, or newest release.
- Up to six recent search terms stored locally, with individual deletion.
<p align="center">
<img width="35%" alt="Screenshot_1786209028" src="https://github.com/user-attachments/assets/ce6b0178-5216-441b-96c6-99be5c7bdcb3" style="margin-right: 15px;" />
<img width="35%" alt="Screenshot_1786209031" src="https://github.com/user-attachments/assets/ad23b995-62a7-4664-8881-bafa4e1e6d86" style="margin-right: 15px;" />
</p>

### Movie details

- Rich TMDB data loaded in one request using `append_to_response` for credits,
  similar movies, reviews, and videos.
- Overview, cast, and community-review tabs.
- Rating, vote count, release year, runtime, genres, director, synopsis, and cast members.
- Similar-movie recommendations.
- Official YouTube trailer selection, with sensible trailer/teaser fallbacks.
- Native sharing through the platform share sheet, including a TMDB link.
- Favorite and watchlist actions for authenticated users.
- Cached detail pages are shown immediately and revalidated from TMDB.
- A 20-entry least-recently-used details cache keeps storage bounded.
<p align="center">
<img width="20%" alt="Screenshot_1786209074" src="https://github.com/user-attachments/assets/5d9080c1-a37d-4342-8a84-25dc1457703d" style="margin-right: 15px;" />
<img width="20%"  alt="Screenshot_1786209071" src="https://github.com/user-attachments/assets/e73ae217-0fa8-4c58-be64-d99754cbbd18" style="margin-right: 15px;" />
<img width="20%"  alt="Screenshot_1786209078" src="https://github.com/user-attachments/assets/fd1233b2-43e0-4afb-906f-66f8284790dd" style="margin-right: 15px;" />
<img width="20%" height="2400" alt="Screenshot_1786719054" src="https://github.com/user-attachments/assets/0f5a91e8-4972-4a9e-9a88-05aaf75be6af" style="margin-right: 15px;"/>
</p>

### Favorites, watchlist, and library

- Add or remove a movie from **Favorites**.
- Add or remove a movie from the **Watchlist**.
- Optimistic UI updates roll back automatically if Supabase rejects a change.
- Library tabs for trailer **History**, **Watchlist**, and **Favorites**.
- Watchlist and favorite entries are fetched in pages of 20 and ordered by the
  time they were added.
- Swipe/remove actions update the interface optimistically and restore the item
  on failure.
- The repository also defines a `watched` list type for future use; the current
  library UI exposes history, watchlist, and favorites.

<p align="center">
<img width="28%" alt="Screenshot_1786719078" src="https://github.com/user-attachments/assets/8de4f369-6cbe-4266-8016-2778f1e019ff" style="margin-right: 15px;"/>
<img width="28%" alt="Screenshot_1786719077" src="https://github.com/user-attachments/assets/df57cab3-cf56-4fdd-aec0-c380c9a67767" style="margin-right: 15px;"/>
<img width="28%" alt="Screenshot_1786719080" src="https://github.com/user-attachments/assets/eabafa28-a7d2-4d5a-a3be-c0374f80a905" style="margin-right: 15px;"/>
</p>

### Community reviews and replies

- Authenticated users can write or update one review per movie.
- Reviews include a 1–10 rating, optional title, written body, and spoiler flag.
- Community reviews display author profile information and reply counts.
- Like/dislike reactions are supported for reviews and replies.
- Selecting the same reaction again removes it; choosing the other reaction
  switches the stored value.
- Users cannot react to their own review or reply.
- Review authors can delete their own reviews.
- Users can open a review discussion, post replies of up to 1,000 characters,
  react to replies, and delete their own replies.
- Review and reply reactions use optimistic updates with rollback on failure.
- **My Reviews** in the profile lists and manages the current user's reviews.
- Guests can read community content, but writing, replying, reacting, and
  deleting require an account.

<p align="center">
<img width="35%" alt="Screenshot_1786719228" src="https://github.com/user-attachments/assets/15bb3c04-8dc6-48a8-bfd1-e1393912e861" style="margin-right: 15px;" />
<img width="35%" alt="Screenshot_1786719241" src="https://github.com/user-attachments/assets/51ecb3f2-f6d7-427f-adb7-d57084fbd9d8" style="margin-right: 15px;" />
</p>

### Profile

- Profile header with name, username, email, biography, and avatar.
- Counts for favorites, watchlist movies, and reviews.
- Edit full name, username, biography, avatar, and password.
- Manage favorite genres after onboarding.
- Open the current user's reviews.
- Support/contact dialog and external link launching.
- Pull-to-refresh and logout confirmation.

<p align="center">
  <img width="35%" alt="Screenshot_1786719087" src="https://github.com/user-attachments/assets/6e047d09-3523-48e9-86a9-d32c62c9eb41" />
<\p>

### User experience

- Five-tab navigation: Home, Browse, AI, Library, and Profile.
- Back navigation returns to Home before leaving the main navigation shell.
- Custom animated splash overlay.
- OpenSans font family and a consistent dark movie-themed design system.
- Reusable shimmer, snack bar, text field, artwork, and navigation components.
- Network-image caching, placeholders, and error fallbacks.
- Centralized error mapping converts Dio, Supabase Auth, database, and storage
  errors into readable messages.

## Account and guest behavior

| Capability | Guest | Signed-in account |
|---|:---:|:---:|
| Onboarding, Home, Browse, and Search | Yes | Yes |
| Movie details, sharing, and trailer playback | Yes | Yes |
| Gemini movie assistant | Yes | Yes |
| AI conversation history | Hive on this device | Supabase + Hive account cache |
| Trailer resume data | Hive under `guest` | Hive under the Supabase user ID |
| Open the Library tab | No; sign-in gate | Yes |
| Favorites and watchlist | No | Supabase-backed |
| Read community reviews/replies | Yes | Yes |
| Write reviews/replies or reactions | No | Yes |
| Profile and favorite-genre management | No; sign-in gate | Yes |

Guest mode is intentionally device-local:

- guest AI sessions use the `guest` Hive namespace;
- guest trailer progress uses the `guest` trailer-history namespace;
- signing in changes the namespace to the authenticated user;
- guest conversations and trailer history are **not merged** into an account;
- account AI history is fetched from Supabase and cached under
  `user:<Supabase user ID>`.

This separation prevents one account from accidentally inheriting another
person's local history on a shared device.

## Trailer history and recursive cache flush

Trailer history is local, scoped, reactive, and designed to avoid a database
write on every player position event.

```text
YouTube player event
       |
       v
updateProgress(position, duration)
       |
       +-- remember latest seconds
       +-- mark progress dirty only when it changed
       +-- start one 5-second periodic timer
                         |
                         v
                   flushProgress()
                         |
              +----------+-----------+
              |                      |
       no changed data          changed data
          -> return          -> save Hive snapshot
                                      |
                           did progress change during save?
                                      |
                              yes -> recursively flush
```

The mechanism is implemented by `TrailerPlaybackCubit` and
`TrailerHistoryRepository`:

1. When a trailer opens, the repository looks up `scopeId::videoKey` in Hive.
2. An incomplete trailer resumes from its saved second. A trailer at or above
   95% is considered complete and starts from the beginning next time.
3. Player updates only change in-memory `_latestSeconds`, `_totalSeconds`, and
   the `_hasUnsavedProgress` dirty flag.
4. One `Timer.periodic` runs every five seconds and calls `flushProgress()`.
5. A flush writes only if progress changed and the total duration is valid.
6. Only one save can run at a time. If a save is already active,
   `flushProgress()` awaits it. When newer progress arrived during that save,
   the method calls itself recursively to persist the newest snapshot.
7. A successful save records `_lastSavedSeconds`; a failed save marks the data
   dirty so a later flush can retry.
8. Completing the video triggers an immediate flush.
9. Closing the trailer cancels the periodic timer and performs a final flush.
10. Values are normalized before storage: watched seconds are clamped between
    zero and total duration, timestamps are UTC, and invalid entries are
    ignored.

Hive watches keys with the active scope prefix. The Library subscribes to that
stream, rebuilds as soon as an entry is saved or removed, and sorts entries by
`updatedAt` descending. This is a periodic dirty-check with a recursive
catch-up flush—not an endlessly recursive background task.

## Gemini AI movie assistant

The AI tab is useful for natural-language discovery that is difficult to
express with normal filters. Example prompts include:

- “Recommend a short science-fiction movie without horror.”
- “What should I watch with my family tonight?”
- “Find movies similar to Interstellar but under two hours.”
- “Compare these recommendations and tell me which is lighter.”
- “Suggest highly rated Korean thrillers from the last five years.”

### Grounded two-stage pipeline

Gemini is used for language understanding and answer writing, while TMDB
remains the source of movie facts.

```text
User message + last 10 messages
              |
              v
     Gemini structured planner
   (intent, titles, genres, year,
    rating, runtime, language...)
              |
              v
         TMDB catalog query
              |
              v
       canonical TMDB movies
              |
              v
      Gemini answer generator
              |
              v
 Validate selected TMDB IDs against
 the catalog returned for this request
              |
              v
 Answer + up to 5 movie cards +
 up to 4 suggested follow-up prompts
```

Important safeguards and behavior:

- Gemini returns schema-constrained JSON through its REST API; no Gemini SDK is
  required.
- Planner intents include recommendation, movie question, comparison, similar,
  clarification, and off-topic handling.
- The planner can express included/excluded genres, title lookup, similar-to,
  original language, year range, minimum rating, and maximum runtime.
- The answer generator can select only TMDB IDs present in the canonical
  catalog for the current request. Unknown or duplicate IDs are discarded.
- At most five movie cards and four suggested replies are accepted.
- Messages are limited to 1,000 characters, and only the latest ten prior
  messages are sent as context.
- User messages appear optimistically while generation is in progress.
- Failed sends retain the same request ID for safe retry.
- Users can start new chats, reopen history, follow suggested prompts, and
  delete sessions.

### AI history persistence

- **Guest:** the optimistic message and final response are saved only in Hive.
- **Authenticated:** the exchange is persisted by the
  `persist_movie_chat_exchange` PostgreSQL RPC and then cached in Hive.
- The RPC writes the session, user message, assistant message, and recommended
  movie relationships as one transaction.
- The request UUID makes persistence idempotent, while the latest migration
  serializes writes to the same session to protect concurrent retries.
- When an authenticated history request fails, the repository falls back to
  its account-scoped Hive cache if available.
- A successful Supabase write is still returned to the UI if refreshing the
  local account cache fails; the next history load can rebuild the cache.

<p align = "center">
<img width="35%"  alt="Ai Chatbot Screenshot" src="https://github.com/user-attachments/assets/6da1ed06-a037-46e0-9135-08d2c788bbde" style="margin-right: 15px;"/>
<img width="35%"  alt="Ai Chatbot Screenshot" src="https://github.com/user-attachments/assets/93ab5bb3-643d-4640-b79b-9afed731e032" style="margin-right: 15px;"/>
</p>

## Architecture

CinMovies uses feature-first organization with presentation, domain, and data
boundaries where a feature needs them.

```text
Presentation (screens, widgets, Cubits, immutable states)
                         |
                         v
Domain (entities and repository contracts where applicable)
                         |
                         v
Data (repository implementations, DTOs, remote/local sources)
              +----------+----------+
              |          |          |
             TMDB     Supabase     Hive
              |          |          |
            Gemini REST API   SharedPreferences/artwork cache
```

Key architectural choices:

- **flutter_bloc / Cubit** manages screen state and async workflows.
- **GetIt** supplies repositories, services, API clients, and Cubit factories.
- **Repository pattern** isolates UI state from HTTP, SQL rows, storage, and
  caching decisions.
- **Sealed `Result<T>` and `AppError` types** make expected failures explicit
  while keeping framework exceptions outside the UI.
- **Equatable** gives immutable states and entities predictable equality.
- **Dio** provides separately configured TMDB and Gemini clients.
- **Feature-first folders** keep each screen's data and presentation code close
  together.

### Startup flow

`main.dart` initializes services in this order:

1. Flutter bindings.
2. `.env` configuration validation.
3. Hive and all application boxes.
4. SharedPreferences.
5. Supabase.
6. GetIt dependency registration.
7. Initial route resolution.
8. `MaterialApp` and the animated splash overlay.

Initial routing follows this rule:

```text
Onboarding not completed -> onboarding
Otherwise no session and not guest -> login
Otherwise -> main application
```

### Main routes

The router contains screens for onboarding, authentication, main navigation,
search, movie sections, movie details, trailer viewing, genre preferences,
profile editing, favorite genres, the current user's reviews, and review
replies. Typed argument objects are used for movie sections, details, trailers,
and reply discussions.

## Data sources and caching

| Data | Source of truth | Local behavior |
|---|---|---|
| Popular/upcoming home feed | TMDB | First 20 items per section in Hive; cache-first revalidation |
| Personalized For You feed | TMDB discover | First page cached per user + normalized genre IDs |
| Movie details/similar/trailer | TMDB | 20-entry LRU-style Hive cache |
| Poster/backdrop images | TMDB image CDN | Cached automatically by `cached_network_image` |
| Browse and search results | TMDB | Results are live; recent search terms are in Hive |
| Account/session | Supabase Auth | Guest and onboarding flags in SharedPreferences |
| Profile/avatar | Supabase database/storage | Loaded on demand |
| Favorite genres | Supabase | Per-user Hive cache + change stream |
| Favorites/watchlist | Supabase | Latest fetched rows also saved as Hive snapshots |
| Community reviews/replies | Supabase | Refetched after mutations |
| Trailer position | Hive | Per guest/user and per YouTube video key |
| Guest AI history | Hive | Full local session/message storage |
| Account AI history | Supabase | Per-account Hive fallback cache |

### Hive boxes

`HiveCacheService` opens these boxes during startup:

| Box | Purpose |
|---|---|
| `search_cache` | Recent search terms |
| `movie_cache` | Locally encoded database movie rows |
| `user_snapshot_cache` | Latest account list snapshots |
| `favorite_genres_cache` | Account-scoped favorite genres |
| `trailer_history` | Scoped trailer progress entries |
| `movie_chat_history` | Scoped AI sessions and messages |
| `catalog_cache_v1` | Home, For You, and movie-detail catalog caches |

## Supabase data model

The Flutter code expects the following backend resources.

### Authentication and profiles

- Supabase email/password Auth.
- `profiles` table for full name, username, bio, avatar URL, and onboarding
  state.
- Public `avatars` storage bucket with policies that allow a user to write to
  their own path.

### Catalog and user library

- `movies` and `movie_genres` catalog tables.
- `genres` lookup table.
- `user_genre_preferences` join table.
- `user_movie_lists` with `favorite`, `watchlist`, and optionally `watched`
  values.
- `cache_movie(...)` RPC, which upserts a TMDB movie and returns its database
  UUID before a list or review relationship is written.

### Reviews

- `user_reviews` with a unique `(user_id, movie_id)` relationship.
- `review_reactions` containing one `like` or `dislike` per user/review.
- `review_replies` and `reply_reactions` from the bundled reply migration.
- `get_review_reply_counts(uuid[])` RPC for efficient reply badges.

### AI chat

- `ai_chat_sessions`.
- `ai_chat_messages`.
- `ai_message_movies`, joining an assistant message to recommended catalog
  movies with a reason and rank.
- `persist_movie_chat_exchange(...)` RPC for atomic, idempotent persistence.

The migrations in [`supabase/migrations`](supabase/migrations) add and secure
AI chat persistence, optimize its row-level security policies, serialize chat
writes, and add review replies/reactions with indexes and policies.

> **Important:** these are incremental migrations. They reference foundational
> tables and functions such as `profiles`, `movies`, `user_reviews`,
> `ai_chat_sessions`, and `cache_movie` that are not created by the migration
> files currently committed to this repository. A new Supabase project must
> receive that base schema (for example, from the original project's schema
> export) before the included migrations can be applied successfully.

The included policies make review/reply reading public while restricting
mutations to permanent authenticated users and owners. AI rows are protected by
owner-based row-level security.

## Packages

### Runtime dependencies

| Package | Version | Role in CinMovies |
|---|---:|---|
| `flutter` | SDK | Cross-platform UI framework |
| `cupertino_icons` | `^1.0.8` | Declared icon set; currently no direct import in `lib/` |
| `dio` | `^5.10.0` | TMDB and Gemini REST clients |
| `flutter_bloc` | `^9.1.1` | Cubit state management and Bloc UI bindings |
| `get_it` | `^9.2.1` | Dependency injection/service locator |
| `equatable` | `^2.1.0` | Value equality for state and domain objects |
| `smooth_page_indicator` | `^2.0.1` | Onboarding page indicator |
| `font_awesome_flutter` | `^11.0.0` | Declared icon package; currently no direct import in `lib/` |
| `fl_chart` | `^1.2.0` | Library donut/progress chart |
| `supabase_flutter` | `^2.16.0` | Auth, PostgreSQL queries/RPC, and Storage |
| `flutter_dotenv` | `^6.0.1` | Loads API configuration from `.env` |
| `hive` | `^2.2.3` | Local key-value persistence |
| `hive_flutter` | `^1.1.0` | Flutter initialization and Hive boxes |
| `shared_preferences` | `^2.5.5` | Onboarding and guest-mode flags |
| `image_picker` | `^1.2.3` | Registration/profile avatar selection |
| `url_launcher` | `^6.3.2` | Profile support/contact links |
| `share_plus` | `^13.3.0` | Native movie sharing |
| `youtube_player_flutter` | `^10.0.1` | In-app YouTube trailer player |
| `cached_network_image` | `^3.4.1` | Cached avatar/cast/network images |
| `uuid` | `^4.5.2` | Conversation, request, and temporary message IDs |

### Development dependencies

| Package | Version | Role |
|---|---:|---|
| `flutter_test` | SDK | Unit and widget testing |
| `flutter_lints` | `^6.0.0` | Static-analysis rules |
| `flutter_launcher_icons` | `^0.14.4` | Generates launcher icons |
| `flutter_native_splash` | `^2.4.8` | Generates native splash assets |

## Getting started

### Prerequisites

- Flutter stable with Dart `3.12.1` or newer in the Dart 3.x line.
- A TMDB account and a **v4 read access token**.
- A Google AI Studio Gemini API key.
- A Supabase project with email/password authentication, the required base
  schema, included migrations, and an `avatars` bucket.
- Platform tooling for the target you intend to run: Android Studio/SDK, Xcode,
  a supported desktop toolchain, or a browser.

### 1. Install dependencies

```shell
flutter pub get
```

### 2. Create environment configuration

Copy `.env.example` to `.env`:

```powershell
Copy-Item .env.example .env
```

Or on macOS/Linux:

```shell
cp .env.example .env
```

Then provide:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-supabase-publishable-key
TMDB_API_KEY=your-tmdb-v4-read-access-token
GEMINI_API_KEY=your-gemini-api-key
GEMINI_MODEL=gemini-3.5-flash-lite
```

`GEMINI_MODEL` is optional and defaults to `gemini-3.5-flash-lite` in the
current source. `SUPABASE_ANON_KEY` can be used as a compatibility fallback if
`SUPABASE_PUBLISHABLE_KEY` is not set.

Do not commit `.env`. It is ignored by Git. Be aware that `pubspec.yaml`
declares `.env` as a Flutter asset, which means its contents can be recovered
from a compiled app.

### 3. Prepare Supabase

1. Create or restore the required foundational schema described above.
2. Create the public `avatars` bucket and user-scoped write policies.
3. Apply the SQL files in `supabase/migrations` in timestamp order.
4. Enable email/password authentication.
5. Confirm that RLS and grants allow public review reading while account data
   remains owner-scoped.

If the project is linked with the Supabase CLI and already has its base schema:

```shell
supabase db push
```

### 4. Run the application

```shell
flutter run
```

To select a device explicitly:

```shell
flutter devices
flutter run -d <device-id>
```

## Project structure

```text
cinmovies_app/
├── assets/
│   ├── fonts/                     # OpenSans font files
│   └── images/                    # Logo, onboarding, and fallback artwork
├── docs/
│   └── AI_MOVIE_ASSISTANT_GUIDE.md
├── lib/
│   ├── core/
│   │   ├── config/                # Environment configuration
│   │   ├── constants/             # API URLs and paths
│   │   ├── di/                    # GetIt registrations
│   │   ├── error/                 # Failures, exceptions, error mapping
│   │   ├── local/                 # Hive and SharedPreferences services
│   │   ├── navigation/            # Routes and router
│   │   ├── network/               # Dio client factories
│   │   ├── supabase/              # Database and storage wrappers
│   │   ├── theme/                 # Shared colors
│   │   └── widgets/               # Reusable application widgets
│   ├── features/
│   │   ├── ai/                    # Gemini/TMDB chat and history
│   │   ├── app/                   # Bootstrap routing
│   │   ├── auth/                  # Auth repository, Cubit, guest prompts
│   │   ├── browse/                # Genre discovery and pagination
│   │   ├── home/                  # Home feed and personalized sections
│   │   ├── library/               # History, watchlist, favorites
│   │   ├── login/ and signup/     # Account UI
│   │   ├── main/                  # Bottom-navigation shell
│   │   ├── movie_details/         # Details, trailer, share, reviews
│   │   ├── movies/                # Shared movie entity/cache/widgets
│   │   ├── onboarding/            # Intro and genre onboarding
│   │   ├── preferences/           # Favorite genre persistence
│   │   ├── profile/               # Account/profile management
│   │   ├── reviews/               # Reviews, replies, reactions
│   │   ├── search/                # Debounced TMDB search
│   │   └── trailers/              # Playback and progress history
│   └── main.dart                  # Application entry point
├── supabase/
│   ├── config.toml
│   └── migrations/                # Incremental SQL migrations
├── test/                          # Unit and widget tests by feature
├── flutter_launcher_icons.yaml
├── flutter_native_splash.yaml
└── pubspec.yaml
```

CinMovies demonstrates how a Flutter application can combine API-driven
catalog discovery, authenticated social features, resilient local caching,
reactive state management, media playback, and a grounded generative-AI
assistant in a single project.

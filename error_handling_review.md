# Error Handling Architecture Review

## Overall Verdict

**The design is solid and well-reasoned — not over-engineering.** The Chain-of-Responsibility pattern via `ErrorMapperRegistry` is a clean, production-grade approach. But there are **3 real issues** and **2 inconsistencies** that need attention.

---

## ✅ What's Done Well

### 1. Chain-of-Responsibility Pattern — Correct
`ErrorMapperRegistry` iterates mappers and returns the first match. This is a textbook CoR implementation. It is **open for extension, closed for modification** (OCP ✓). Adding a new error source only means adding a new `ErrorMapper` implementation.

### 2. Single Responsibility — Respected
Each mapper handles exactly one concern:
- `DioErrorMapper` → Dio HTTP failures
- `SupabaseErrorMapper` → Auth / DB / Storage failures
- `NetworkErrorMapper` → raw `SocketException` / `TimeoutException`
- `CoreExceptionErrorMapper` → your own custom exceptions

### 3. Typed Failures with Enums — Correct
`AuthFailure(type: AuthFailureType.invalidCredentials, ...)` lets the UI switch on the *type* rather than parsing strings. This is the right pattern — the UI layer stays decoupled from Supabase error codes.

### 4. `Either<Failure, T>` in `AuthRepository` — Correct
Returning `Either` instead of throwing keeps errors explicit at the call site. This is idiomatic Clean Architecture for Dart.

---

## ❌ Real Issues

### Issue 1 — Inconsistent Error Handling Across Repositories

`AuthRepository` uses `Either<Failure, T>` and catches errors properly. But `ReviewRepository` and `MovieRepository` **do not** — they `await` Supabase calls and let exceptions bubble up unhandled:

```dart
// review_repository.dart — no try/catch, no Either
Future<void> upsertReview(...) async {
  final movieId = await _movieRepository.cacheMovie(movie);
  await _database.from('user_reviews').upsert({...}); // ← throws PostgrestException if it fails
}
```

This violates the **contract you established**: callers expect either an `Either` or a caught exception. A raw `PostgrestException` escaping into the cubit/presentation layer breaks Clean Architecture's boundary.

**Fix:** Wrap every repository method in `try/catch` and return `Either<Failure, T>`:

```dart
Future<Either<Failure, void>> upsertReview({...}) async {
  try {
    final movieId = await _movieRepository.cacheMovie(movie);
    await _database.from('user_reviews').upsert({...});
    return const Right(null);
  } catch (e) {
    return Left(_errorMapper.map(e));
  }
}
```

---

### Issue 2 — `_mapError` Duplication in `AuthRepository`

`AuthRepository` has this helper:

```dart
Failure _mapError(Object error) {
  return _errorMapper.tryMap(error) ??
      const UnknownFailure(message: 'Something went wrong. Please try again.');
}
```

But `ErrorMapperRegistry` already has a `map()` method that does exactly this (line 21–23 of `error_mapper.dart`). The repository should call `_errorMapper.map(error)` directly — **but only if you inject `ErrorMapperRegistry` instead of `ErrorMapper`**.

The cleanest fix is to change the field type from `ErrorMapper` to `ErrorMapperRegistry`, which exposes `.map()`:

```dart
// Before
final ErrorMapper _errorMapper;

// After — inject the concrete registry
final ErrorMapperRegistry _errorMapper;
```

Then simplify:
```dart
catch (error) {
  return Left(_errorMapper.map(error)); // no null fallback needed
}
```

---

### Issue 3 — `SupabaseErrorMapper` Handles Three Responsibilities

`SupabaseErrorMapper` has 270 lines mapping Auth, Database, and Storage errors. While cohesive in the sense that they all come from Supabase, this is a **fat mapper** that's hard to test in isolation. Any new auth error code means editing this class even if you only care about storage.

**Recommendation:** Split into three focused mappers and register them separately:

```dart
const ErrorMapperRegistry defaultErrorMapper = ErrorMapperRegistry([
  CoreExceptionErrorMapper(),
  NetworkErrorMapper(),
  SupabaseAuthErrorMapper(),      // was: part of SupabaseErrorMapper
  SupabasePostgrestErrorMapper(), // was: part of SupabaseErrorMapper
  SupabaseStorageErrorMapper(),   // was: part of SupabaseErrorMapper
  DioErrorMapper(),
]);
```

This is a **mild refactor**, not over-engineering — each file stays under ~60 lines and unit tests become trivial.

---

## ⚠️ Minor Issues

### Issue 4 — `defaultErrorMapper` is a Global Constant (DI Bypass)

`default_error_mapper.dart` exports a top-level `const` instance:

```dart
const ErrorMapperRegistry defaultErrorMapper = ErrorMapperRegistry([...]);
```

And repositories use it as a default parameter:

```dart
AuthRepository(this._database, this._preferences, [this._errorMapper = defaultErrorMapper]);
```

This is a **hidden dependency** — it bypasses your DI container (`GetIt`). In tests, you can still swap the mapper since it's a default parameter, so this is *acceptable for now*. But ideally, `ErrorMapperRegistry` should be registered in `injection_container.dart` and injected explicitly:

```dart
sl.registerLazySingleton<ErrorMapperRegistry>(() => const ErrorMapperRegistry([...]));
sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl(), sl(), sl()));
```

### Issue 5 — `NetworkErrorMapper` is Redundant with `DioErrorMapper`

`DioErrorMapper` already handles connection timeouts and socket-level errors via `DioExceptionType.connectionError`. `NetworkErrorMapper` catches raw `SocketException`s — which only appear if you use raw `http` or `dart:io` sockets directly. Since you only use Dio for HTTP, `NetworkErrorMapper` will almost never trigger for network errors (Dio wraps them first). It's not harmful, but it's dead weight unless you add a raw HTTP layer.

---

## Summary Table

| Aspect | Status | Note |
|---|---|---|
| SOLID — SRP | ⚠️ Partial | `SupabaseErrorMapper` is too large |
| SOLID — OCP | ✅ Correct | Registry pattern allows extension |
| SOLID — LSP | ✅ Correct | All mappers honor `ErrorMapper` contract |
| SOLID — ISP | ✅ Correct | `ErrorMapper` interface is minimal |
| SOLID — DIP | ⚠️ Partial | `defaultErrorMapper` is a global, not injected |
| Clean Arch — Data boundary | ❌ Broken | `ReviewRepository` / `MovieRepository` leak exceptions |
| Either pattern | ⚠️ Inconsistent | Only `AuthRepository` uses it |
| Over-engineering? | ✅ No | The pattern is appropriate for the project scale |

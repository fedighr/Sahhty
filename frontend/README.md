# Sahhty — Flutter Auth Module

> Production-ready authentication module for the Sahhty intelligent health tracking app (Tunisia).

---

## 📁 Project Structure

```
lib/
├── main.dart                              # App entry point
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart            # Base URL, endpoints, keys, timeouts
│   ├── routes/
│   │   ├── app_router.dart               # go_router configuration
│   │   └── app_router.g.dart             # Generated provider
│   ├── theme/
│   │   └── app_theme.dart                # AppColors + ThemeData
│   └── utils/
│       ├── app_failure.dart              # Sealed failure hierarchy
│       ├── app_logger.dart               # Logger wrapper
│       └── validators.dart               # All form validators
│
├── data/
│   ├── models/
│   │   └── auth_model.dart               # SignInRequest, SignUpRequest, AuthTokens
│   ├── services/
│   │   ├── auth_interceptor.dart         # Dio interceptor (token inject + 401 handling)
│   │   ├── auth_service.dart             # Raw API calls (Dio)
│   │   ├── dio_client.dart               # Dio factory + providers
│   │   └── token_storage_service.dart    # flutter_secure_storage wrapper
│   └── repositories/
│       └── auth_repository.dart          # Domain bridge — orchestrates service + storage
│
└── features/
    └── auth/
        ├── providers/
        │   ├── auth_state.dart           # Sealed AuthState classes
        │   └── auth_notifier.dart        # Riverpod Notifier (business logic)
        ├── screens/
        │   ├── splash_screen.dart        # Session check + animated splash
        │   ├── login_screen.dart         # Sign in form
        │   └── register_screen.dart      # Sign up form (all 9 fields)
        └── widgets/
            ├── auth_header.dart          # Logo + title widget
            ├── auth_text_field.dart      # Animated input + PasswordTextField
            ├── password_strength_indicator.dart
            ├── primary_button.dart       # Gradient button with loading state
            └── snackbar_helper.dart      # Error/success/info snackbars
```

---

## 🚀 Quick Start

### 1. Prerequisites
- Flutter 3.10+
- Dart 3.0+

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure backend URL
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://api.sahhty.tn/api/v1';
```

### 4. Android secure storage setup
The app uses `EncryptedSharedPreferences` on Android. No extra config needed.

### 5. iOS setup
Add to `ios/Runner/Info.plist` if not present:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Sahhty uses secure storage for your health data</string>
```

### 6. Run
```bash
flutter run
```

---

## 🏗 Architecture Decisions

### Clean Architecture Layers

```
UI Layer (Screens/Widgets)
        ↓ consumes
Notifier (auth_notifier.dart) — pure business logic, no Flutter imports
        ↓ calls
Repository (auth_repository.dart) — orchestrates service + storage
        ↓ uses
Service (auth_service.dart) — raw HTTP via Dio
        ↓ + Storage
TokenStorageService — secure token persistence
```

### Why Sealed AuthState?
Exhaustive pattern matching ensures the UI handles every state. The compiler forces you to handle new states when added:
```dart
switch (state) {
  case AuthInitial():   // ...
  case AuthLoading():   // ...
  case AuthAuthenticated(): // ...
  case AuthError():     // ...
  case AuthUnauthenticated(): // ...
}
```

### Why two Dio instances?
- `authDio` — for `/signin`, `/signup` — no token attached
- `protectedDio` — for all other endpoints — auto-attaches `Bearer` token

This prevents circular dependency (the interceptor needs storage to get the token, but signin creates the tokens).

### Repository pattern
The repository acts as the single source of truth. It:
1. Calls the service for network operations
2. Saves tokens to secure storage after success
3. Maps all exceptions to domain failures (`AppFailure` hierarchy)

---

## 🧪 Testing Strategy

### Run all tests
```bash
flutter test
```

### Layer-by-layer testing

| Layer | What to mock | Test file |
|-------|-------------|-----------|
| `AuthService` | `Dio` (use `dioAdapter`) | `test/data/services/auth_service_test.dart` |
| `AuthRepository` | `IAuthService` + `ITokenStorageService` | `test/data/repositories/auth_repository_test.dart` |
| `AuthNotifier` | `IAuthRepository` | `test/features/auth/providers/auth_notifier_test.dart` |
| Validators | none | `test/core/utils/validators_test.dart` |

All interfaces (`IAuthService`, `IAuthRepository`, `ITokenStorageService`) exist explicitly for mocking.

---

## 🔒 Token Management

### Current flow
```
Login/Register → API returns {access, refresh}
              → Saved to flutter_secure_storage (encrypted)
              → AuthInterceptor reads access token on every request
              → 401 response → tokens cleared (logout)
```

### Future refresh flow (prepared, not wired)
In `auth_interceptor.dart`, find the comment block in `onError`:
```dart
// ── Future: Implement token refresh here ──────────────────────────
// 1. Check if we have a refresh token
// 2. Call POST /users/auth/token/refresh
// 3. Save new tokens
// 4. Retry original request
// 5. If refresh fails → logout
```

When the Django refresh endpoint is ready:
1. Implement `refreshTokens()` in `AuthService`
2. Add to `AuthRepository`
3. Wire it in `AuthInterceptor.onError` for 401 responses
4. Use a `Completer<void>` to queue concurrent requests during refresh

---

## 🌐 Google Sign-In Extension Strategy

The codebase is ready for Google login. To add it:

1. Add dependency: `google_sign_in: ^6.2.1`
2. Create `GoogleAuthService` implementing `IAuthService`
3. Send the Google `idToken` to your Django backend endpoint `POST /users/auth/google/`
4. Backend returns the same `{access, refresh}` response structure
5. Reuse `AuthRepository.signIn()` — just pass a different service

The `LoginScreen` already has a Google button stub ready to wire up.

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod ^2.5.1` | State management |
| `dio ^5.4.3` | HTTP client |
| `flutter_secure_storage ^9.2.2` | Encrypted token storage |
| `go_router ^13.2.4` | Declarative navigation |
| `flutter_animate ^4.5.0` | Micro-animations |
| `google_fonts ^6.2.1` | Poppins typography |
| `equatable ^2.0.5` | Value equality for models/states |
| `logger ^2.3.0` | Structured logging |
| `intl ^0.19.0` | Date formatting |

---

## 🗺 Navigation Flow

```
App Launch
    └── SplashScreen (checks stored tokens)
            ├── Token found → ProfileSelectionScreen
            └── No token → LoginScreen
                    ├── Sign in success → ProfileSelectionScreen
                    └── "S'inscrire" → RegisterScreen
                            └── Register success → ProfileSelectionScreen
```

---

## ⚙ Implementation Order (step-by-step)

1. `pubspec.yaml` — add dependencies, run `flutter pub get`
2. `core/constants/app_constants.dart` — set your backend URL
3. `core/utils/app_failure.dart` — failure hierarchy
4. `core/utils/validators.dart` — form validation logic
5. `core/theme/app_theme.dart` — design system
6. `data/models/auth_model.dart` — request/response models
7. `data/services/token_storage_service.dart` — secure storage
8. `data/services/dio_client.dart` — HTTP client factory
9. `data/services/auth_interceptor.dart` — attach tokens
10. `data/services/auth_service.dart` — API calls
11. `data/repositories/auth_repository.dart` — domain bridge
12. `features/auth/providers/auth_state.dart` — state model
13. `features/auth/providers/auth_notifier.dart` — business logic
14. `features/auth/widgets/*` — reusable UI components
15. `features/auth/screens/*` — screens
16. `core/routes/app_router.dart` — navigation
17. `main.dart` — wire everything
18. Tests

---

## 🇹🇳 Tunisian Context

- Phone validation: Tunisian format (`+216 XX XXX XXX`)
- UI language: French (primary) with Arabic support
- Date format: `dd/MM/yyyy`
- Phone prefix shown as `+216` in the form

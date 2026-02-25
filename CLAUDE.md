# CLAUDE.md

This file provides guidance to Claude Code when working with this Flutter apartment management application.

## Commands

```bash
# Development
flutter run                        # Run on connected device/emulator
flutter run -d chrome              # Run in browser (web)
flutter run --flavor development   # Run with specific flavor

# Build
flutter build apk                  # Build Android APK
flutter build appbundle            # Build Android App Bundle
flutter build ios                  # Build iOS (macOS only)

# Testing
flutter test                       # Run all unit/widget tests
flutter test test/widget_test.dart # Run a specific test file

# Code Quality
flutter analyze                    # Static analysis (dart analyze)
dart fix --apply                   # Auto-apply lint fixes
dart format .                      # Format all Dart files

# Dependencies
flutter pub get                    # Install dependencies
flutter pub upgrade                # Upgrade dependencies
flutter pub outdated               # Check for outdated packages

# Code Generation (if added in future)
dart run build_runner build        # Run code generation
dart run build_runner watch        # Watch mode for code gen
```

The app connects to a NestJS backend. Set the base URL in `lib/core/constants/app_constants.dart`.

## Architecture

Feature-based clean architecture with Riverpod state management.

**Stack:** Flutter + Dart, Riverpod 3.x (NotifierProvider), GoRouter 17.x, Dio 5.x, flutter_secure_storage.

**Top-level structure:**
```
lib/
├── core/          # Shared infrastructure (API client, storage, constants, utils)
├── features/      # Feature modules (auth, landlord, tenant)
├── router/        # GoRouter configuration and redirect logic
├── theme/         # Material 3 theme, color palette, status colors
└── main.dart      # Entry point — ProviderScope wraps the app
```

**Feature module layout** (each feature follows this pattern):
```
features/<feature>/
├── data/
│   ├── models/        # Immutable data models with fromJson/toJson and computed getters
│   └── repositories/  # API call wrappers — one repo per domain entity
└── presentation/
    ├── providers/     # Riverpod NotifierProvider — state + business logic
    └── screens/       # Widgets (screens + sub-widgets/dialogs/cards)
```

**Key modules:**
- `auth/` — Login, register, change password; splash/home; `AuthNotifier` manages global auth state
- `landlord/` — Space/room management, memberships, payments, maintenance (landlord view), notices, audit logs
- `tenant/` — View memberships, join spaces, maintenance requests (tenant view), payments

## State Management

Riverpod 3.x `NotifierProvider` pattern throughout. Every feature follows the same shape:

```dart
// 1. Immutable state class
class FeatureState {
  final List<Model> items;
  final bool isLoading;
  final String? error;
  const FeatureState({...});
  FeatureState copyWith({...}) { ... }
}

// 2. Notifier wraps repository calls
class FeatureNotifier extends Notifier<FeatureState> {
  @override
  FeatureState build() => const FeatureState();
  // Methods update state via copyWith()
}

// 3. Top-level provider
final featureProvider = NotifierProvider<FeatureNotifier, FeatureState>(
  FeatureNotifier.new,
);
```

**Auth state** is the single source of truth for who is logged in. All protected routes read `authProvider`. The JWT token is stored in encrypted secure storage and auto-injected into every API request via a Dio interceptor.

## Navigation

GoRouter with a reactive redirect callback that listens to `authProvider`:

- During auth initialization → splash screen (`/`)
- Unauthenticated → `/auth/login`
- Authenticated LANDLORD → `/landlord`
- Authenticated TENANT → `/tenant`
- `/landlord` and `/tenant` are tab-based `MainScreen` widgets

Route parameters are passed via path params (`:spaceId`, `:requestId`) or via `state.extra` for complex objects.

## Data Layer

**ApiClient** (`lib/core/api/api_client.dart`):
- Dio instance with auth interceptor (auto-attaches `Bearer` token) and logging interceptor
- Clears token on 401; raises `ApiException` for all errors
- Use `apiClient.get/post/patch/delete` or `apiClient.uploadMultipart` for file uploads

**ApiResponse** (`lib/core/api/api_response.dart`):
- All backend responses are wrapped: `{ ok, data, message, page }`
- `ApiResponse<T>.fromJson(json, fromJsonT)` deserializes the `data` field

**Repositories** contain all API logic. Providers depend on repositories — screens depend only on providers.

## Key Conventions

- **Immutable models:** All models use `copyWith()`. Never mutate a model in place.
- **Computed getters:** Add derived properties directly to models (e.g., `user.fullName`, `membership.activeLeases`, `payment.isDueToday`). Keep presentation logic out of widgets.
- **Currency:** All monetary values are integers (cents/smallest unit). Use `CurrencyFormatter` for display.
- **Images:** Maintenance requests support both a legacy base64 `imageData` field and a newer relative `imageUrl`. New uploads use multipart form data.
- **Status enums:** Enums carry `displayName` getters and factory constructors for JSON deserialization. Follow the same pattern when adding new statuses.
- **Role colors:** Landlord = Blue `#2563EB`, Tenant = Green `#10B981`. Status badge colors are defined in `AppTheme`.
- **Logging:** Use `print()` with descriptive prefixes during development. Remove or guard verbose prints before release.
- **Secure storage keys** are defined in `AppConstants` — do not hardcode storage key strings elsewhere.

## Role-Based Feature Split

| Feature | Landlord | Tenant |
|---|---|---|
| Spaces | Full CRUD + join codes | View joined spaces |
| Rooms | Full CRUD | View assigned rooms |
| Memberships | Approve/reject requests, view active | Request to join, view own memberships |
| Payments | View summaries, mark as paid | View own payment history |
| Maintenance | Update status, add comments, view all | Submit requests, add comments, cancel |
| Notices | Create and send | View received notices |
| Audit logs | View action history | — |

## Development Guidelines

- Read a file before modifying it. Never propose changes to code you haven't seen.
- Do not refactor unrelated features; focus changes on what was asked.
- Preserve all existing providers, repositories, and routing logic unless explicitly changing them.
- Follow the existing `NotifierProvider` state pattern for any new feature — do not introduce `StateNotifierProvider`, `ChangeNotifier`, or `setState` patterns.
- New models must include `fromJson`, `toJson`, `copyWith`, and relevant computed getters.
- New routes must be added to `app_router.dart` and follow the existing redirect/guard pattern.
- Never hard-delete UI logic for roles — add role checks, don't remove branches.

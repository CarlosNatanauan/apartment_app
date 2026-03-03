<div align="center">

# SpaceNest

**Smart rental management**

A fullstack mobile app for landlords to manage spaces, rooms, and tenants — and for tenants to handle leases, rent, and maintenance requests.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![NestJS](https://img.shields.io/badge/NestJS-10.x-E0234E?style=flat-square&logo=nestjs&logoColor=white)](https://nestjs.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Prisma-4169E1?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org)

</div>

---

## Demo

[![Watch the Demo](https://img.youtube.com/vi/OduM3MMHklo/maxresdefault.jpg)](https://www.youtube.com/watch?v=OduM3MMHklo)

---

## Screenshots

### Tenant
<img src="https://github.com/user-attachments/assets/af500198-bc52-4041-b5c2-2f95b9150494" width="1000" alt="Tenant Screens" />

### Landlord
<img src="https://github.com/user-attachments/assets/120fe48c-39fa-4445-b4dc-8cf727973982" width="1000" alt="Landlord Screens" />

---

## Tech Stack

### Mobile — Flutter

| | |
|---|---|
| **Framework** | Flutter + Dart |
| **State Management** | Riverpod 3.x (NotifierProvider) |
| **Navigation** | GoRouter 17.x |
| **HTTP Client** | Dio 5.x |
| **Auth Storage** | flutter_secure_storage |
| **Google Sign-In** | google_sign_in |

### Backend — NestJS

| | |
|---|---|
| **Framework** | NestJS + TypeScript |
| **Database** | PostgreSQL |
| **ORM** | Prisma |
| **Auth** | JWT · Google OAuth 2.0 · bcrypt |
| **File Uploads** | Multer (multipart/form-data) |
| **Validation** | class-validator · class-transformer |

---

## Features

### As a Tenant
- Sign up with email/password or Google — choose your role on first login
- Join an apartment space using a landlord-issued join code
- Submit maintenance requests with up to 10 photos
- Track request status in real time (Pending → In Progress → Completed)
- Comment on maintenance threads with your landlord
- View rent history and upcoming payments
- Delete account with full data cleanup

### As a Landlord
- Create and manage apartment spaces and rooms
- Approve or reject tenant join requests
- Assign tenants to rooms and configure monthly rent
- View all maintenance requests across every space you own
- Update request status and reply in the comment thread
- Post notices visible to all members of a space
- Mark rent payments as paid or unpaid per tenant
- Full audit log of all major actions

---

## Mobile Architecture

```
lib/
├── core/           # ApiClient (Dio + auth interceptor), secure storage, constants
├── features/
│   ├── auth/       # Login, register, Google sign-in, role selection, profile
│   ├── landlord/   # Spaces, rooms, memberships, payments, maintenance, notices, audit logs
│   └── tenant/     # Join spaces, maintenance requests, payments, notices
├── router/         # GoRouter config with reactive auth-based redirects
├── theme/          # Material 3 theme, role colors, status badge colors
└── main.dart       # ProviderScope entry point
```

Each feature follows a consistent three-layer structure: `data/models` → `data/repositories` → `presentation/providers` → `presentation/screens`.

**Riverpod `NotifierProvider` pattern** — Every feature has an immutable state class with `copyWith()`, a `Notifier` that wraps repository calls, and a top-level provider. State is never mutated in place.

**Reactive navigation** — GoRouter's `redirect` callback listens to auth state changes via `GoRouterRefreshStream`. Unauthenticated users are sent to `/auth/login`; authenticated users are routed to their role-specific dashboard (`/landlord` or `/tenant`). New Google users are intercepted and sent to `/role-selection` before reaching the app.

**Dio interceptors** — A single `ApiClient` instance auto-attaches the `Bearer` JWT token to every request and clears it on 401, keeping auth logic out of repositories.

**Role-based UI** — Landlord screens use blue (`#2563EB`); tenant screens use green (`#10B981`). Status badge colors and role accents are defined centrally in `AppTheme` and applied consistently across all cards, headers, and pills.

**Immutable models** — All models include `fromJson`, `toJson`, `copyWith`, and computed getters (e.g. `membership.activeLeases`, `payment.isDueToday`) to keep business logic out of widgets.

---

## Backend Architecture

```
src/
├── auth/           # JWT + Google OAuth, role guard, RBAC (TENANT / LANDLORD / ADMIN)
├── spaces/         # Apartment complexes, join codes, audit logs, payment summaries
├── rooms/          # Rooms within a space, soft deletes
├── memberships/    # Tenant-to-space/room assignments, approval workflow
├── maintenance/    # Requests, multi-image uploads, status updates, comment threads
├── common/         # Global response interceptor, pagination DTO, validation pipe
└── prisma/         # PrismaService singleton, shared globally across all modules
```

**Standardized API responses** — A global `ResponseInterceptor` wraps every response in `{ ok, data, message }` so the Flutter client always gets a consistent shape.

**Auth providers** — Users have a `provider` field (`LOCAL` | `GOOGLE`). Google users skip the password check on account deletion and role selection happens on first login via `PATCH /auth/me/role`.

**Soft deletes** — Spaces and rooms use `deletedAt` instead of hard deletes to preserve historical rent records and maintenance history.

**Multi-image maintenance** — Images are stored in a `MaintenanceImage` relation table (one-to-many) supporting up to 10 photos per request, with cascade deletes when a request is removed.

**Audit logging** — Major landlord actions (approve tenant, update maintenance status, remove member, etc.) are recorded in an `AuditLog` table with actor ID, target IDs, and a JSON metadata field.

**Cursor pagination** — All list endpoints use cursor-based pagination (`id` + `createdAt desc`) for consistent performance as data grows.

---

## API Endpoints

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| `POST` | `/auth/register` | — | Register with email/password |
| `POST` | `/auth/login` | — | Login |
| `POST` | `/auth/google` | — | Google sign-in (returns `isNewUser`) |
| `PATCH` | `/auth/me/role` | Any | Set role after first Google login |
| `DELETE` | `/auth/account` | Any | Delete account + all data |
| `POST` | `/spaces` | Landlord | Create a space |
| `GET` | `/spaces/my` | Landlord | List owned spaces |
| `POST` | `/spaces/join` | Tenant | Join a space with a code |
| `GET` | `/spaces/:id/members` | Landlord | List members |
| `GET` | `/spaces/:id/payments/summary` | Landlord | Rent payment summary |
| `POST` | `/spaces/:id/rooms` | Landlord | Add a room |
| `POST` | `/memberships/:id/approve` | Landlord | Approve tenant |
| `POST` | `/memberships/:id/room-leases` | Landlord | Assign room + set rent |
| `POST` | `/maintenance` | Tenant | Submit request + images |
| `GET` | `/maintenance/my` | Tenant | View own requests |
| `GET` | `/landlord/maintenance/all` | Landlord | All requests across spaces |
| `PATCH` | `/maintenance/:id/status` | Landlord | Update request status |
| `POST` | `/maintenance/:id/comments` | Both | Add comment to thread |
| `POST` | `/spaces/:id/notices` | Landlord | Post a space notice |

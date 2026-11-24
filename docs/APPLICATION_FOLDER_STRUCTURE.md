# LaganStaff — Application Folder & Monorepo Structure

**Document Version:** 1.0.0  
**Status:** Approved for Phase 0 Planning  
**Architecture Pattern:** Feature-Driven Modular Architecture across Mobile, Web, and Backend  

---

## 1. Top-Level Repository Architecture

To maintain clear boundaries between the mobile app, admin portal, and backend code while allowing unified versioning, the project is structured as a clean multi-project workspace:

```
lagan-staff/
├── .github/                     # CI/CD Workflows (Linting, Test, Build APK, Deploy Admin)
├── apps/
│   ├── mobile/                  # Flutter Mobile Application (Workers & Business Owners)
│   └── admin/                   # Next.js 14+ Admin Dashboard (Internal Operators)
├── docs/                        # Complete Architecture & Requirements Documentation
├── supabase/                    # Supabase Infrastructure (Migrations, Functions, Seeds)
└── README.md                    # Project Entry & Local Development Instructions
```

---

## 2. Flutter Mobile Application (`apps/mobile`)

```
apps/mobile/
├── android/                     # Native Android Gradle configuration & Keystore
├── ios/                         # Native iOS Xcode project
├── assets/
│   ├── icons/                   # App icons, SVG iconography
│   ├── images/                  # Illustrated empty states, placeholders
│   └── fonts/                   # Bundled local fonts (fallback for offline)
├── lib/
│   ├── app/
│   │   ├── app.dart             # LaganStaffApp root widget (Theme, Router wiring)
│   │   └── router.dart          # GoRouter configuration & role-based route guards
│   ├── core/
│   │   ├── config/              # App environment variables & Supabase client init
│   │   ├── constants/           # UI constants, color palettes, spacing, API endpoints
│   │   ├── errors/              # Failure models, AppException definitions
│   │   ├── services/            # Device services (Geolocator, Camera/ImagePicker, Storage)
│   │   ├── theme/               # Material 3 typography, Light/Dark color schemes
│   │   ├── utils/               # Date formatters (Intl), phone validators, helpers
│   │   └── widgets/             # Reusable atomic UI (AppButton, AppTextField, LoadingIndicator)
│   ├── features/
│   │   ├── authentication/      # Phone OTP input, verification, session listener
│   │   │   ├── data/            # AuthRepository, SupabaseAuthDataSource
│   │   │   ├── presentation/    # LoginScreen, OtpVerificationScreen, AuthNotifier
│   │   ├── onboarding/          # Role selection (Worker vs Owner) routing
│   │   │   └── presentation/    # RoleSelectionScreen
│   │   ├── worker/              # Worker registration, skills, location, selfie upload
│   │   │   ├── data/            # WorkerRepository (selfie upload, profile completion)
│   │   │   ├── presentation/    # WorkerProfileScreen, SelfieCaptureScreen
│   │   ├── owner/               # Business profile setup, owner dashboard
│   │   │   ├── data/            # BusinessRepository
│   │   │   ├── presentation/    # BusinessProfileScreen, OwnerDashboardScreen
│   │   ├── jobs/                # Job creation (Owner) & Job discovery feed (Worker)
│   │   │   ├── data/            # JobRepository, JobFilterDataSource
│   │   │   ├── presentation/    # JobFeedScreen, JobDetailsScreen, CreateJobScreen
│   │   ├── applications/        # Apply action & application tracking
│   │   │   ├── data/            # ApplicationRepository
│   │   │   ├── presentation/    # WorkerApplicationsScreen, OwnerApplicantsScreen
│   │   ├── bookings/            # Confirmed bookings & shift details
│   │   │   ├── data/            # BookingRepository
│   │   │   ├── presentation/    # BookingDetailsScreen, ShiftSummaryWidget
│   │   ├── attendance/          # Shift check-in / check-out verification
│   │   └── notifications/       # Local & remote notification state
│   ├── shared/
│   │   └── models/              # Immutable Freezed/JSON models (Profile, Job, Booking)
│   └── main.dart                # Application entrypoint (Dependency injection, Riverpod scope)
├── pubspec.yaml                 # Dependencies and asset declarations
└── analysis_options.yaml        # Strict Dart lint rules
```

---

## 3. Next.js Admin Dashboard (`apps/admin`)

```
apps/admin/
├── public/                      # Static branding, favicons, logos
├── src/
│   ├── app/                     # Next.js App Router (Layouts & Pages)
│   │   ├── (auth)/
│   │   │   └── login/           # Admin authentication screen
│   │   ├── (dashboard)/
│   │   │   ├── layout.tsx       # Persistent sidebar, header, role guard
│   │   │   ├── page.tsx         # Operations Overview & KPI cards
│   │   │   ├── job-approvals/   # First-job approval queue & review interface
│   │   │   ├── workers/         # Registered workers directory, selfie inspection
│   │   │   ├── owners/          # Registered business owners & business listings
│   │   │   ├── jobs/            # Master job history across all statuses
│   │   │   ├── bookings/        # Shift booking audit & attendance records
│   │   │   ├── categories/      # Category & skill taxonomy management
│   │   │   └── audit-logs/      # Immutable administrative audit ledger
│   ├── components/              # Reusable UI components (Shadcn UI / Tailwind)
│   │   ├── ui/                  # Button, Dialog, Table, Badge, Card
│   │   └── layout/              # Sidebar, Header, Breadcrumbs
│   ├── features/                # Domain-specific components & server actions
│   │   ├── approvals/           # JobApprovalCard, RejectionModal
│   │   └── audit/               # AuditLogTimeline
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts        # Client-side Supabase browser client
│   │   │   ├── server.ts        # Server Component Supabase SSR client
│   │   │   └── admin.ts         # Service-Role client (Server Actions only)
│   │   └── utils.ts             # CN class merger, date formatters
│   ├── services/                # Backend API & RPC abstraction
│   └── types/                   # Database generated TypeScript types
├── package.json                 # Next.js, React, Tailwind, Supabase dependencies
├── tailwind.config.ts           # Styling theme & design system
└── tsconfig.json                # TypeScript strict configuration
```

---

## 4. Supabase Infrastructure (`supabase`)

```
supabase/
├── migrations/                  # Sequential SQL migration files
│   ├── 20261118000001_create_core_tables.sql
│   ├── 20261118000002_enable_rls_policies.sql
│   ├── 20261118000003_create_rpc_functions.sql
│   └── 20261118000004_create_storage_buckets.sql
├── functions/                   # Supabase Edge Functions (Deno / TypeScript)
│   ├── send-dlt-sms/            # Custom SMS gateway webhook (Indian DLT)
│   └── notify-job-status/       # Push notifications handler (Future Phase)
├── seed.sql                     # Master categories, test skills, Ghazipur localities
└── config.toml                  # Supabase CLI local configuration
```

---

## 5. Environment Variable Management

Each sub-project maintains strictly isolated environment configuration files:

### 5.1 Flutter Mobile (`apps/mobile/.env`)
```bash
# PUBLIC VALUES ONLY - Bundled in Flutter application
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
APP_ENV=production # development | staging | production
```

### 5.2 Next.js Admin (`apps/admin/.env.local`)
```bash
# Public Keys (Client Browser)
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOi...

# STRICTLY CONFIDENTIAL (Vercel Server Environment Only)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...
ADMIN_PORTAL_SECRET=...
```

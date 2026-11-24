# LaganStaff — Hyperlocal Workforce Marketplace

LaganStaff is an on-demand hyperlocal staffing platform connecting businesses (marriage lawns, catering services, tent houses, and event organizers) with temporary gig workers in **Ghazipur, Uttar Pradesh, India**.

---

## 1. Monorepo Architecture

```
LaganStaff/
├── apps/
│   ├── mobile/         # Flutter mobile application (Worker & Owner modules)
│   └── admin/          # Next.js 14+ Admin Dashboard (admin.<domain>)
├── supabase/
│   ├── migrations/     # PostgreSQL database migrations & RLS policies
│   └── functions/      # Supabase Edge Functions
├── docs/               # System architecture & Google Stitch specifications
│   └── stitch-prompts/ # Stitch UI generation prompts (Worker, Owner, Admin)
├── .env.example        # Master environment variables template
├── .gitignore          # Strict git ignore (prevents secret leaks)
└── README.md           # Project documentation & local setup instructions
```

---

## 2. Prerequisites & Environment Setup

- **Flutter SDK:** 3.47+ (Dart 3.13+)
- **Android SDK:** Platform 36.0.0+ / JDK 21
- **Node.js:** v20+ (Node v26 verified)
- **Supabase Account:** [https://supabase.com](https://supabase.com) (or local Supabase CLI)

---

## 3. Running the Flutter Mobile App (`apps/mobile`)

The mobile application is a single unified Flutter app providing separate role-based experiences for **Workers** and **Business Owners**.

### 3.1 Install Dependencies
```bash
cd apps/mobile
flutter pub get
```

### 3.2 Verify Analysis & Tests
```bash
flutter analyze
flutter test
```

### 3.3 Launch on Android Emulator or Physical Device
```bash
# Launch available Android emulator:
flutter emulators --launch Medium_Phone_API_37.0

# Run with custom Supabase credentials:
flutter run --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
            --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

---

## 4. Running the Next.js Admin Dashboard (`apps/admin`)

The Admin Web Dashboard operates at `admin.<your-domain>` for first-job moderation and platform governance.

### 4.1 Install Dependencies
```bash
cd apps/admin
npm install
```

### 4.2 Configure Environment
```bash
cp .env.example .env.local
# Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY in .env.local
```

### 4.3 Run Linting & Production Build
```bash
npm run lint
npm run build
```

### 4.4 Start Local Development Server
```bash
npm run dev
# Open http://localhost:3000 in your browser
```

---

## 5. Unified Supabase BaaS Architecture

Both the Flutter mobile application and the Next.js Admin Dashboard target the **exact same Supabase project**:
- **Authentication:** Phone number + 4-Digit PIN (using synthetic email mapping under the hood; zero SMS cost and no DLT delay).
- **PostgreSQL Database:** PostgreSQL 15+ with Row Level Security (RLS) and atomic capacity RPCs.
- **Storage:** Private `worker-selfies` bucket for identity selfies ($<100\text{ KB}$ client compressed).
- **Gate Attendance:** 4-digit Duty Pass Check-in PIN verification between worker and owner.

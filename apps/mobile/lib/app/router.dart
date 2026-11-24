import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/attendance/screens/owner_attendance_history_screen.dart';
import '../features/attendance/screens/owner_attendance_roster_screen.dart';
import '../features/attendance/screens/worker_bookings_screen.dart';
import '../features/attendance/screens/worker_work_history_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/models/user_profile.dart';
import '../features/auth/presentation/access_denied_screen.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../features/auth/presentation/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_verification_screen.dart';
import '../features/jobs/screens/owner_jobs/owner_job_detail_screen.dart';
import '../features/jobs/screens/owner_jobs/owner_jobs_list_screen.dart';
import '../features/jobs/screens/post_job/post_job_wizard_screen.dart';
import '../features/jobs/screens/worker_jobs/worker_job_detail_screen.dart';
import '../features/jobs/screens/worker_jobs/worker_job_discovery_screen.dart';
import '../features/notifications/screens/notification_center_screen.dart';
import '../features/notifications/screens/notification_preferences_screen.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/owner/screens/onboarding/owner_onboarding_screen.dart';
import '../features/owner/screens/owner_home_screen.dart';
import '../features/owner/screens/owner_job_history_screen.dart';
import '../features/owner/screens/owner_profile_placeholder.dart';
import '../features/worker/screens/onboarding/worker_onboarding_screen.dart';
import '../features/worker/screens/worker_home_screen.dart';
import '../features/worker/screens/worker_profile_placeholder.dart';

class AppRouterListenable extends ChangeNotifier {
  AppRouterListenable(Ref ref) {
    ref.listen<bool>(
      authNotifierProvider.select((s) => s.status == AuthStatus.authenticated),
      (prev, next) {
        if (prev != next) notifyListeners();
      },
    );

    ref.listen<AppUserRole?>(
      authNotifierProvider.select((s) => s.userProfile?.primaryRole),
      (prev, next) {
        if (prev != next) notifyListeners();
      },
    );
  }
}

final routerListenableProvider = Provider<AppRouterListenable>((ref) {
  return AppRouterListenable(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authRepository = ref.read(authRepositoryProvider);
      final authState = ref.read(authNotifierProvider);

      final currentPath = state.uri.path;
      final isAuthUser = authRepository.currentUser != null;
      final role = authState.userProfile?.primaryRole;

      // 1. Unauthenticated users can only view /login or /verify-otp
      if (!isAuthUser) {
        if (currentPath == '/login' || currentPath == '/verify-otp') {
          return null; // allow access
        }
        return '/login';
      }

      // 2. Authenticated user without an assigned role MUST select a role
      if (role == null) {
        if (currentPath == '/select-role') {
          return null; // allow access
        }
        return '/select-role';
      }

      // 3. Admin account protection: mobile app strictly denies Admin accounts
      if (role == AppUserRole.admin) {
        if (currentPath == '/access-denied') {
          return null;
        }
        return '/access-denied';
      }

      // 4. Worker role isolation: Worker cannot access Owner routes or public auth pages
      if (role == AppUserRole.worker) {
        if (currentPath.startsWith('/owner') ||
            currentPath.startsWith('/jobs') ||
            currentPath == '/login' ||
            currentPath == '/verify-otp' ||
            currentPath == '/select-role') {
          return '/worker/home';
        }
        return null; // allow access to /worker/*
      }

      // 5. Owner role isolation: Owner cannot access Worker routes or public auth pages
      if (role == AppUserRole.owner) {
        if (currentPath.startsWith('/worker') ||
            currentPath == '/login' ||
            currentPath == '/verify-otp' ||
            currentPath == '/select-role') {
          return '/owner/home';
        }
        return null; // allow access to /owner/* and /jobs/*
      }

      return null;
    },
    routes: [
      // Public Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/select-role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),

      // Protected Worker Routes
      GoRoute(
        path: '/worker/home',
        builder: (context, state) => const WorkerHomeScreen(),
      ),
      GoRoute(
        path: '/worker/jobs',
        builder: (context, state) => const WorkerJobDiscoveryScreen(),
      ),
      GoRoute(
        path: '/worker/jobs/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WorkerJobDetailScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/worker/bookings',
        builder: (context, state) => const WorkerBookingsScreen(),
      ),
      GoRoute(
        path: '/worker/work-history',
        builder: (context, state) => const WorkerWorkHistoryScreen(),
      ),
      GoRoute(
        path: '/worker/onboarding',
        builder: (context, state) => const WorkerOnboardingScreen(),
      ),
      GoRoute(
        path: '/worker/profile',
        builder: (context, state) => const WorkerProfilePlaceholderScreen(),
      ),
      GoRoute(
        path: '/worker/profile-placeholder',
        builder: (context, state) => const WorkerProfilePlaceholderScreen(),
      ),

      // Protected Owner Routes
      GoRoute(
        path: '/owner/home',
        builder: (context, state) => const OwnerHomeScreen(),
      ),
      GoRoute(
        path: '/jobs/create',
        builder: (context, state) => const PostJobWizardScreen(),
      ),
      GoRoute(
        path: '/jobs/my-jobs',
        builder: (context, state) => const OwnerJobsListScreen(),
      ),
      GoRoute(
        path: '/jobs/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OwnerJobDetailScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/owner/attendance/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          return OwnerAttendanceRosterScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/owner/attendance-history',
        builder: (context, state) => const OwnerAttendanceHistoryScreen(),
      ),
      GoRoute(
        path: '/owner/onboarding',
        builder: (context, state) => const OwnerOnboardingScreen(),
      ),
      GoRoute(
        path: '/owner/job-history',
        builder: (context, state) => const OwnerJobHistoryScreen(),
      ),
      GoRoute(
        path: '/owner/profile',
        builder: (context, state) => const OwnerProfilePlaceholderScreen(),
      ),
      GoRoute(
        path: '/owner/profile-placeholder',
        builder: (context, state) => const OwnerProfilePlaceholderScreen(),
      ),
      GoRoute(
        path: '/owner/roster/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          return OwnerAttendanceRosterScreen(jobId: jobId);
        },
      ),

      // Notification Center & Preferences Routes
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
    ],
  );
});

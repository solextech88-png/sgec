import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/session_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/home/student_home_shell.dart';
import '../features/consultant_dashboard/consultant_dashboard_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/universities/university_detail_screen.dart';
import '../features/documents/document_upload_screen.dart';
import '../features/consent/consent_sign_screen.dart';

/// Single route table for all three roles. `/` redirects to the correct
/// role-specific home shell based on SessionState, so deep links and app
/// restarts always land the user in the right place.
///
/// NOTE: this rebuilds the GoRouter whenever sessionProvider changes, which
/// is simple and fine for this scaffold but resets navigation state on
/// every session change. For production, switch to GoRouter's
/// `refreshListenable` (backed by a ChangeNotifier wrapping SessionState)
/// so the router instance stays stable and only re-evaluates `redirect`.
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

GoRouter buildRouter(Ref ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register'
          || state.matchedLocation == '/otp';

      if (!session.isLoggedIn && !loggingIn) return '/login';
      if (session.isLoggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            userId: extra['userId'] as String? ?? '',
            channel: extra['channel'] as String? ?? 'email',
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          switch (session.role) {
            case AppRole.consultant:
              return const ConsultantDashboardScreen();
            case AppRole.admin:
              return const AdminDashboardScreen();
            case AppRole.student:
            case AppRole.unknown:
              return const StudentHomeShell();
          }
        },
      ),
      GoRoute(
        path: '/universities/:id',
        builder: (context, state) =>
            UniversityDetailScreen(universityId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/documents', builder: (context, state) => const DocumentUploadScreen()),
      GoRoute(path: '/consent', builder: (context, state) => const ConsentSignScreen()),
    ],
  );
}

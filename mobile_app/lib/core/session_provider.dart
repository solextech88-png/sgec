import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Shared ApiClient instance for the whole app.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

enum AppRole { student, consultant, admin, unknown }

AppRole roleFromString(String? raw) {
  switch (raw) {
    case 'STUDENT':
      return AppRole.student;
    case 'CONSULTANT':
      return AppRole.consultant;
    case 'ADMIN':
      return AppRole.admin;
    default:
      return AppRole.unknown;
  }
}

/// Holds whether the user is logged in and their role, so the router can
/// redirect to the right role-specific home screen. Call `refresh()` after
/// login/logout to update every listener (e.g. the GoRouter redirect).
class SessionState {
  final bool isLoggedIn;
  final AppRole role;
  const SessionState({required this.isLoggedIn, required this.role});
  static const initial = SessionState(isLoggedIn: false, role: AppRole.unknown);
}

class SessionNotifier extends StateNotifier<SessionState> {
  final ApiClient _api;
  SessionNotifier(this._api) : super(SessionState.initial) {
    _load();
  }

  Future<void> _load() async {
    final token = await _api.getToken();
    final role = await _api.getRole();
    state = SessionState(isLoggedIn: token != null, role: roleFromString(role));
  }

  Future<void> loginSucceeded(String token, String role) async {
    await _api.saveSession(token, role);
    state = SessionState(isLoggedIn: true, role: roleFromString(role));
  }

  Future<void> logout() async {
    await _api.clearSession();
    state = SessionState.initial;
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref.read(apiClientProvider)),
);

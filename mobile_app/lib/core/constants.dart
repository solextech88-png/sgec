/// App-wide constants. Keep environment-specific values (API base URL) in
/// one place so switching between local/staging/prod is a single-line edit.
class AppConstants {
  AppConstants._();

  static const String appName = "Smart Global Education Consult";

  // Android emulator maps 10.0.2.2 -> host machine's localhost.
  // Replace with your deployed API URL for staging/production builds
  // (ideally injected via --dart-define at build time, not hardcoded).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  static const String secureStorageTokenKey = 'sgec_auth_token';
  static const String secureStorageRoleKey = 'sgec_role';
}

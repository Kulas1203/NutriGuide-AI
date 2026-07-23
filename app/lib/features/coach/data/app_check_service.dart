// Named parameters cannot be initializing formals for private fields
// (Dart forbids `this._x` as a named parameter), so the constructor assigns
// them in its initializer list.
// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/config/env.dart';

/// Firebase App Check boundary.
///
/// The backend `coachAsk` endpoint rejects any request that does not carry a
/// valid App Check token in the `X-Firebase-AppCheck` header (see
/// backend/functions/src/index.ts). This service mints that token on the
/// client so legitimate app installs can reach the AI Coach while automated
/// abuse is blocked.
///
/// The app deliberately talks to Firebase over REST and ships no Firebase
/// SDK, so token minting is expressed as a small seam:
///
///  * [NoopAppCheckService] — no token (dev builds / App Check not yet
///    configured). The backend will refuse Coach calls, which is correct:
///    dev builds use [DevCoachService] and never hit the backend.
///  * [DebugAppCheckService] — exchanges an App Check *debug token* (a secret
///    registered in the Firebase console, App Check → Apps → Manage debug
///    tokens) for a real, short-lived App Check token via Firebase's
///    `exchangeDebugToken` endpoint. This lets staging/dev verify the full
///    App Check-enforced Coach flow (including from the web/Chrome build)
///    without the native SDK. The raw debug token is NOT a valid App Check
///    token on its own — it must be exchanged first, exactly as the SDK does.
///
/// For a signed Android production release, a real Play Integrity token must
/// be minted by the native `firebase_app_check` plugin. That path is added at
/// release time (see docs/APP_CHECK.md); it plugs in behind this same
/// interface without touching callers.
abstract class AppCheckService {
  /// A fresh App Check token, or null when App Check is not configured for
  /// this build (in which case backend Coach calls are expected to fail).
  Future<String?> token();
}

/// No-op implementation: never returns a token. Used in dev builds and any
/// build without App Check configured.
class NoopAppCheckService implements AppCheckService {
  const NoopAppCheckService();

  @override
  Future<String?> token() async => null;
}

/// Exchanges a Firebase App Check *debug token* for a real App Check token.
///
/// Debug tokens are registered per-app in the Firebase console and are only
/// meant for development/CI. The exchange calls the public App Check REST
/// endpoint with the project's public web API key; the returned token is
/// short-lived and cached until shortly before it expires.
class DebugAppCheckService implements AppCheckService {
  DebugAppCheckService({
    required String debugToken,
    required String appId,
    required String projectNumber,
    required String apiKey,
    Dio? dio,
  }) : _debugToken = debugToken,
       _appId = appId,
       _projectNumber = projectNumber,
       _apiKey = apiKey,
       _dio = dio ?? Dio();

  final String _debugToken;
  final String _appId;
  final String _projectNumber;
  final String _apiKey;
  final Dio _dio;

  String? _cachedToken;
  DateTime? _expiry;

  bool get _configured =>
      _debugToken.isNotEmpty &&
      _appId.isNotEmpty &&
      _projectNumber.isNotEmpty &&
      _apiKey.isNotEmpty;

  @override
  Future<String?> token() async {
    if (!_configured) return null;
    if (_cachedToken != null &&
        _expiry != null &&
        DateTime.now().isBefore(
          _expiry!.subtract(const Duration(minutes: 1)),
        )) {
      return _cachedToken;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://firebaseappcheck.googleapis.com/v1/projects/'
        '$_projectNumber/apps/$_appId:exchangeDebugToken',
        queryParameters: {'key': _apiKey},
        data: {'debugToken': _debugToken},
      );
      final data = response.data ?? const {};
      final token = data['token'] as String?;
      if (token == null) return null;
      _cachedToken = token;
      // ttl looks like "3600s"; default to an hour if it can't be parsed.
      final ttl = (data['ttl'] as String?)?.replaceAll('s', '') ?? '';
      final seconds = int.tryParse(ttl) ?? 3600;
      _expiry = DateTime.now().add(Duration(seconds: seconds));
      return token;
    } on DioException {
      // If the exchange fails, send no token; the backend will 401 and the
      // Coach surfaces a "could not be reached" message rather than crashing.
      return null;
    }
  }
}

/// Selects the App Check implementation for the current build.
///
/// A debug token, when fully configured, is used regardless of flavor so
/// staging can exercise the enforced backend. Otherwise no token is sent (dev
/// builds do not reach the backend; a production Android build wires the
/// native Play Integrity provider — see docs/APP_CHECK.md).
AppCheckService defaultAppCheckService() {
  if (AppEnvironment.appCheckDebugToken.isNotEmpty) {
    return DebugAppCheckService(
      debugToken: AppEnvironment.appCheckDebugToken,
      appId: AppEnvironment.firebaseAppId,
      projectNumber: AppEnvironment.firebaseProjectNumber,
      apiKey: AppEnvironment.firebaseApiKey,
    );
  }
  return const NoopAppCheckService();
}

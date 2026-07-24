import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/env.dart';

class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

class AuthException implements Exception {
  AuthException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Authentication boundary.
///
/// Production builds use [FirebaseRestAuthService] (Firebase Authentication
/// via its REST API, tokens in platform secure storage). Development builds
/// without Firebase credentials use [DevLocalAuthService], which exists only
/// behind [AppEnvironment.useDevStub] and cannot be constructed in
/// production (guarded in bootstrap and by tests).
abstract class AuthService {
  Future<AuthUser?> currentUser();
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);

  /// Requires recent reauthentication with [password] (destructive action,
  /// master requirement §15).
  Future<void> deleteAccount({required String password});

  /// Fresh ID token for backend calls, or null when signed out.
  Future<String?> idToken();
}

/// Firebase Authentication over REST (identitytoolkit / securetoken APIs).
///
/// No Firebase SDK is required on-device; the API key is a public client
/// identifier (abuse is limited server-side by App Check + rules — see
/// docs/THREAT_MODEL.md). Refresh tokens live in EncryptedSharedPreferences
/// via flutter_secure_storage.
class FirebaseRestAuthService implements AuthService {
  FirebaseRestAuthService({
    Dio? dio,
    FlutterSecureStorage? storage,
    String? apiKey,
  }) : _dio = dio ?? Dio(),
       _storage = storage ?? const FlutterSecureStorage(),
       _apiKey = apiKey ?? AppEnvironment.firebaseApiKey;

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String _apiKey;

  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUid = 'auth_uid';
  static const _kEmail = 'auth_email';

  String? _cachedIdToken;
  DateTime? _idTokenExpiry;

  static const String _identityBase =
      'https://identitytoolkit.googleapis.com/v1';
  static const String _tokenBase = 'https://securetoken.googleapis.com/v1';

  @override
  Future<AuthUser?> currentUser() async {
    final uid = await _storage.read(key: _kUid);
    final email = await _storage.read(key: _kEmail);
    if (uid == null || email == null) return null;
    return AuthUser(uid: uid, email: email);
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      _passwordFlow('accounts:signInWithPassword', email, password);

  @override
  Future<AuthUser> signUp({required String email, required String password}) =>
      _passwordFlow('accounts:signUp', email, password);

  Future<AuthUser> _passwordFlow(
    String endpoint,
    String email,
    String password,
  ) async {
    final data = await _post('$_identityBase/$endpoint', {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });
    final user = AuthUser(
      uid: data['localId'] as String,
      email: data['email'] as String? ?? email,
    );
    await _storage.write(
      key: _kRefreshToken,
      value: data['refreshToken'] as String,
    );
    await _storage.write(key: _kUid, value: user.uid);
    await _storage.write(key: _kEmail, value: user.email);
    _cacheIdToken(data['idToken'] as String, data['expiresIn'] as String?);
    return user;
  }

  @override
  Future<void> signOut() async {
    _cachedIdToken = null;
    _idTokenExpiry = null;
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUid);
    await _storage.delete(key: _kEmail);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _post('$_identityBase/accounts:sendOobCode', {
      'requestType': 'PASSWORD_RESET',
      'email': email,
    });
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = await currentUser();
    if (user == null) throw AuthException('not_signed_in', 'Not signed in.');
    // Reauthenticate first — deletion is destructive.
    final data = await _post('$_identityBase/accounts:signInWithPassword', {
      'email': user.email,
      'password': password,
      'returnSecureToken': true,
    });
    await _post('$_identityBase/accounts:delete', {
      'idToken': data['idToken'] as String,
    });
    await signOut();
  }

  @override
  Future<String?> idToken() async {
    if (_cachedIdToken != null &&
        _idTokenExpiry != null &&
        DateTime.now().isBefore(
          _idTokenExpiry!.subtract(const Duration(minutes: 5)),
        )) {
      return _cachedIdToken;
    }
    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (refreshToken == null) return null;
    final data = await _post('$_tokenBase/token', {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    });
    final newRefresh = data['refresh_token'] as String?;
    if (newRefresh != null) {
      await _storage.write(key: _kRefreshToken, value: newRefresh);
    }
    _cacheIdToken(data['id_token'] as String, data['expires_in'] as String?);
    return _cachedIdToken;
  }

  void _cacheIdToken(String token, String? expiresInSeconds) {
    _cachedIdToken = token;
    _idTokenExpiry = DateTime.now().add(
      Duration(seconds: int.tryParse(expiresInSeconds ?? '') ?? 3600),
    );
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: {'key': _apiKey},
        data: body,
      );
      return response.data ?? const {};
    } on DioException catch (e) {
      throw _translate(e);
    }
  }

  AuthException _translate(DioException e) {
    final data = e.response?.data;
    String code = 'network';
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        code = error['message'] as String;
      }
    }
    final message = switch (code) {
      'EMAIL_NOT_FOUND' ||
      'INVALID_PASSWORD' ||
      'INVALID_LOGIN_CREDENTIALS' => 'Email or password is incorrect.',
      'EMAIL_EXISTS' => 'An account already exists for this email.',
      'WEAK_PASSWORD : Password should be at least 6 characters' ||
      'WEAK_PASSWORD' => 'Please choose a password with at least 8 characters.',
      'TOO_MANY_ATTEMPTS_TRY_LATER' =>
        'Too many attempts. Please wait a moment and try again.',
      'USER_DISABLED' => 'This account has been disabled.',
      'network' =>
        'Could not reach the sign-in service. Check your connection and '
            'try again.',
      _ => 'Sign-in failed. Please try again.',
    };
    return AuthException(code, message);
  }
}

/// Development-only local auth stub.
///
/// Exists so the full app can be exercised without Firebase credentials.
/// Construction throws outside dev builds; the release pipeline builds with
/// APP_ENV=prod + USE_DEV_STUB=false and
/// [AppEnvironment.guardProductionIntegrity] enforces the combination.
class DevLocalAuthService implements AuthService {
  DevLocalAuthService(this._prefs) {
    if (!AppEnvironment.useDevStub) {
      throw StateError(
        'DevLocalAuthService must never be constructed outside dev builds.',
      );
    }
  }

  final SharedPreferences _prefs;

  static const _kAccounts = 'dev_auth_accounts';
  static const _kSession = 'dev_auth_session';

  Map<String, dynamic> get _accounts =>
      (jsonDecode(_prefs.getString(_kAccounts) ?? '{}') as Map)
          .cast<String, dynamic>();

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  @override
  Future<AuthUser?> currentUser() async {
    final session = _prefs.getString(_kSession);
    if (session == null) return null;
    final decoded = (jsonDecode(session) as Map).cast<String, dynamic>();
    return AuthUser(
      uid: decoded['uid'] as String,
      email: decoded['email'] as String,
    );
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email.toLowerCase()];
    if (account == null) {
      throw AuthException('not_found', 'Email or password is incorrect.');
    }
    final map = (account as Map).cast<String, dynamic>();
    if (_hash(password, map['salt'] as String) != map['hash']) {
      throw AuthException('bad_password', 'Email or password is incorrect.');
    }
    final user = AuthUser(
      uid: map['uid'] as String,
      email: email.toLowerCase(),
    );
    await _prefs.setString(
      _kSession,
      jsonEncode({'uid': user.uid, 'email': user.email}),
    );
    return user;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    final accounts = _accounts;
    final key = email.toLowerCase();
    if (accounts.containsKey(key)) {
      throw AuthException(
        'exists',
        'An account already exists for this email.',
      );
    }
    if (password.length < 8) {
      throw AuthException(
        'weak',
        'Please choose a password with at least 8 characters.',
      );
    }
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final uid =
        'dev_${sha256.convert(utf8.encode(key)).toString().substring(0, 16)}';
    accounts[key] = {'uid': uid, 'salt': salt, 'hash': _hash(password, salt)};
    await _prefs.setString(_kAccounts, jsonEncode(accounts));
    final user = AuthUser(uid: uid, email: key);
    await _prefs.setString(
      _kSession,
      jsonEncode({'uid': user.uid, 'email': user.email}),
    );
    return user;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_kSession);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw AuthException(
      'dev_stub',
      'Password reset requires the Firebase backend (dev build).',
    );
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = await currentUser();
    if (user == null) throw AuthException('not_signed_in', 'Not signed in.');
    // Reauth in dev too, so the flow matches production behavior.
    await signIn(email: user.email, password: password);
    final accounts = _accounts..remove(user.email);
    await _prefs.setString(_kAccounts, jsonEncode(accounts));
    await signOut();
  }

  @override
  Future<String?> idToken() async {
    final user = await currentUser();
    return user == null ? null : 'dev-token-${user.uid}';
  }
}

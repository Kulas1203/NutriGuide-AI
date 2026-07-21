import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/auth_service.dart';

enum SessionStatus { loading, signedOut, signedIn }

class SessionState {
  const SessionState({required this.status, this.user, this.error});

  final SessionStatus status;
  final AuthUser? user;
  final String? error;
}

class SessionController extends Notifier<SessionState> {
  late AuthService _auth;

  @override
  SessionState build() {
    _auth = ref.watch(authServiceProvider);
    _restore();
    return const SessionState(status: SessionStatus.loading);
  }

  Future<void> _restore() async {
    final user = await _auth.currentUser();
    state = SessionState(
      status: user == null ? SessionStatus.signedOut : SessionStatus.signedIn,
      user: user,
    );
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _auth.signIn(email: email.trim(), password: password));

  Future<bool> signUp(String email, String password) =>
      _run(() => _auth.signUp(email: email.trim(), password: password));

  Future<bool> _run(Future<AuthUser> Function() action) async {
    state = const SessionState(status: SessionStatus.loading);
    try {
      final user = await action();
      state = SessionState(status: SessionStatus.signedIn, user: user);
      return true;
    } on AuthException catch (e) {
      state = SessionState(status: SessionStatus.signedOut, error: e.message);
      return false;
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email.trim());
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const SessionState(status: SessionStatus.signedOut);
  }

  /// Called after account deletion clears local + server state.
  void markSignedOut() =>
      state = const SessionState(status: SessionStatus.signedOut);
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

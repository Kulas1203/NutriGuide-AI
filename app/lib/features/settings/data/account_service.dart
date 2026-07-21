import 'dart:convert';

import '../../../core/storage/local_store.dart';
import '../../auth/data/auth_service.dart';

/// Handles data export and full account deletion.
///
/// Deletion is a two-part operation: local wipe (always) and server-side
/// deletion of the auth account and Firestore data. The backend
/// `deleteAccount` function performs the authoritative server deletion; this
/// service triggers it and clears the device (master requirement §15).
class AccountService {
  AccountService({
    required this.store,
    required this.auth,
    required this.collections,
  });

  final LocalStore store;
  final AuthService auth;
  final List<String> collections;

  /// Full JSON export of the user's local data. Excludes credentials and any
  /// secure-storage values. The user can save/share this file.
  Future<String> exportJson() async {
    final data = await store.exportAll(collections);
    final user = await auth.currentUser();
    final export = {
      'app': 'NutriGuide AI',
      'exportedAt': DateTime.now().toIso8601String(),
      'account': {'uid': user?.uid, 'email': user?.email},
      'data': data,
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Deletes the account. Requires the password for reauthentication before
  /// the destructive step. Wipes local data regardless of server outcome so
  /// no residual health data remains on the device.
  Future<void> deleteAccount({required String password}) async {
    try {
      await auth.deleteAccount(password: password);
    } finally {
      await store.wipeAll();
    }
  }
}

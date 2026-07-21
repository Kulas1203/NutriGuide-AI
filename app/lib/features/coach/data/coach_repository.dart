import 'dart:convert';

import '../../../core/storage/local_store.dart';
import '../domain/chat_message.dart';
import '../domain/safety_classifier.dart';
import 'coach_service.dart';

/// Orchestrates the AI Coach: runs the client safety pre-screen, streams the
/// answer from the [CoachService], and persists conversation history only
/// when the user has AI history enabled (master requirement §15).
///
/// When history is disabled the app remains fully functional; messages exist
/// only in memory for the current session and are never written to disk.
class CoachRepository {
  CoachRepository({
    required this.service,
    required this.store,
    SafetyClassifier? classifier,
  }) : _classifier = classifier ?? SafetyClassifier();

  final CoachService service;
  final LocalStore store;
  final SafetyClassifier _classifier;
  static const String _collection = 'coach_history';
  static const String _historyId = 'messages';

  SafetyResult preScreen(String question) => _classifier.classify(question);

  Future<List<ChatMessage>> loadHistory({required bool historyEnabled}) async {
    if (!historyEnabled) return [];
    final json = await store.get(_collection, _historyId);
    if (json == null) return [];
    final list = (jsonDecode(json['messages'] as String) as List)
        .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return list;
  }

  Future<void> saveHistory(
    List<ChatMessage> messages, {
    required bool historyEnabled,
  }) async {
    if (!historyEnabled) return;
    await store.put(_collection, _historyId, {
      'messages': jsonEncode(messages.map((m) => m.toJson()).toList()),
    });
  }

  /// Permanently deletes stored conversation history.
  Future<void> deleteHistory() => store.clearCollection(_collection);

  Stream<CoachChunk> ask({
    required String question,
    required CoachContext context,
    required List<ChatMessage> history,
    required String? authToken,
  }) => service.ask(
    question: question,
    context: context,
    history: history,
    authToken: authToken,
  );
}

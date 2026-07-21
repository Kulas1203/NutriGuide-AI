import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/utils/dates.dart';
import '../../auth/data/auth_service.dart';
import '../../diets/domain/diet_catalog.dart';
import '../../profile/application/profile_controller.dart';
import '../data/coach_repository.dart';
import '../data/coach_service.dart';
import '../domain/chat_message.dart';
import '../domain/safety_classifier.dart';

class CoachState {
  const CoachState({
    this.messages = const [],
    this.sending = false,
    this.draft = '',
    this.questionsToday = 0,
    this.error,
    this.loading = true,
  });

  final List<ChatMessage> messages;
  final bool sending;

  /// The user's unsent question is preserved here if a send fails (master
  /// requirement §16), so it is never lost.
  final String draft;
  final int questionsToday;
  final String? error;
  final bool loading;

  CoachState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? draft,
    int? questionsToday,
    Object? error = _sentinel,
    bool? loading,
  }) => CoachState(
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    draft: draft ?? this.draft,
    questionsToday: questionsToday ?? this.questionsToday,
    error: error == _sentinel ? this.error : error as String?,
    loading: loading ?? this.loading,
  );

  static const Object _sentinel = Object();
}

class CoachController extends Notifier<CoachState> {
  late CoachRepository _repo;
  late AuthService _auth;
  static const _uuid = Uuid();
  StreamSubscription<CoachChunk>? _sub;

  @override
  CoachState build() {
    _repo = ref.watch(coachRepositoryProvider);
    _auth = ref.watch(authServiceProvider);
    ref.onDispose(() => _sub?.cancel());
    _load();
    return const CoachState();
  }

  bool get _historyEnabled =>
      ref.read(profileControllerProvider).profile?.aiHistoryEnabled ?? true;

  Future<void> _load() async {
    final messages = await _repo.loadHistory(historyEnabled: _historyEnabled);
    state = CoachState(
      messages: messages,
      questionsToday: _countTodayQuestions(messages),
      loading: false,
    );
  }

  int _countTodayQuestions(List<ChatMessage> messages) {
    final today = Dates.dayKey(DateTime.now());
    return messages
        .where(
          (m) => m.role == ChatRole.user && Dates.dayKey(m.createdAt) == today,
        )
        .length;
  }

  void setDraft(String value) => state = state.copyWith(draft: value);

  Future<void> send(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || state.sending) return;

    final entitlements = ref.read(entitlementsProvider);
    if (!entitlements.canAskAiQuestion(state.questionsToday)) {
      state = state.copyWith(
        error:
            'You have reached today’s question limit (${entitlements.aiQuestionsPerDay}). '
            'This resets tomorrow.',
      );
      return;
    }

    // 1) Client-side safety pre-screen — runs before anything leaves device.
    final safety = _repo.preScreen(trimmed);
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: trimmed,
      createdAt: DateTime.now(),
    );

    if (safety.action == SafetyAction.blockEmergency ||
        safety.action == SafetyAction.blockRefer) {
      // Do NOT contact the model. Respond with the safety message directly.
      final safeReply = ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.coach,
        text: safety.userMessage ?? SafetyMessages.emergency,
        createdAt: DateTime.now(),
        safetyCategory: safety.category,
        professionalReferral: true,
        confidence: 'individual',
      );
      final messages = [...state.messages, userMessage, safeReply];
      state = state.copyWith(
        messages: messages,
        draft: '',
        questionsToday: state.questionsToday + 1,
        error: null,
      );
      await _repo.saveHistory(messages, historyEnabled: _historyEnabled);
      return;
    }

    // 2) Allowed (possibly with caution). Stream the answer.
    final placeholder = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.coach,
      text: '',
      createdAt: DateTime.now(),
      status: MessageStatus.streaming,
    );
    var messages = [...state.messages, userMessage, placeholder];
    state = state.copyWith(
      messages: messages,
      sending: true,
      draft: '',
      questionsToday: state.questionsToday + 1,
      error: null,
    );

    final profileState = ref.read(profileControllerProvider);
    final profile = profileState.profile;
    final targets = profileState.targets;
    final context = CoachContext(
      dietId: profile?.dietId ?? 'balanced',
      calorieTarget: targets?.calories ?? 2000,
      allergies: profile?.allergies ?? const [],
      goal: DietCatalog.byId(profile?.dietId ?? 'balanced').name,
      requiresProfessionalGuidance:
          profile?.requiresProfessionalGuidance ?? false,
      historyEnabled: _historyEnabled,
    );

    try {
      final token = await _auth.idToken();
      ChatMessage current = placeholder;
      final cautionCategory = safety.action == SafetyAction.allowWithCaution
          ? safety.category
          : null;

      await for (final chunk in _repo.ask(
        question: trimmed,
        context: context,
        history: state.messages,
        authToken: token,
      )) {
        if (chunk.isFinal && chunk.structured != null) {
          current = _mergeStructured(current, chunk.structured!, safety);
        } else if (chunk.textDelta != null) {
          // Backend streams structured JSON lines; try to parse, else treat
          // as plain text delta (dev stub streams plain text).
          final parsed = _tryParseStructured(chunk.textDelta!);
          current = parsed != null
              ? _mergeStructured(current, parsed, safety)
              : current.copyWith(
                  text: chunk.textDelta,
                  status: MessageStatus.streaming,
                );
        }
        messages = [for (final m in messages) m.id == current.id ? current : m];
        state = state.copyWith(messages: messages);
      }

      // Prepend a caution note when applicable, without hiding the answer.
      if (cautionCategory != null && safety.userMessage != null) {
        current = current.copyWith(
          professionalReferral: true,
          limitations: '${safety.userMessage}\n\n${current.limitations ?? ''}'
              .trim(),
        );
      }
      current = current.copyWith(status: MessageStatus.complete);
      messages = [for (final m in messages) m.id == current.id ? current : m];
      state = state.copyWith(messages: messages, sending: false);
      await _repo.saveHistory(messages, historyEnabled: _historyEnabled);
    } catch (e) {
      // Fail gracefully: no fabricated fallback, keep the user's question as
      // a restorable draft, remove the empty placeholder.
      final withoutPlaceholder = messages
          .where((m) => m.id != placeholder.id)
          .toList();
      state = state.copyWith(
        messages: withoutPlaceholder,
        sending: false,
        draft: trimmed,
        questionsToday: state.questionsToday - 1,
        error:
            'The AI Coach could not be reached. Your question was saved — '
            'check your connection and try again.',
      );
    }
  }

  ChatMessage _mergeStructured(
    ChatMessage current,
    ChatMessage structured,
    SafetyResult safety,
  ) => current.copyWith(
    text: structured.text,
    explanation: structured.explanation,
    nextSteps: structured.nextSteps,
    limitations: structured.limitations,
    sources: structured.sources,
    confidence: structured.confidence,
    professionalReferral: structured.professionalReferral,
    status: MessageStatus.streaming,
  );

  ChatMessage? _tryParseStructured(String line) {
    try {
      final json = jsonDecode(line);
      if (json is Map<String, dynamic> && json.containsKey('text')) {
        return ChatMessage.fromJson({
          'id': _uuid.v4(),
          'role': 'coach',
          'createdAt': DateTime.now().toIso8601String(),
          ...json,
        });
      }
    } on FormatException {
      // Not JSON; caller treats it as a plain-text delta.
    }
    return null;
  }

  Future<void> clearHistory() async {
    await _repo.deleteHistory();
    state = const CoachState(messages: [], loading: false);
  }

  void dismissError() => state = state.copyWith(error: null);
}

final coachControllerProvider = NotifierProvider<CoachController, CoachState>(
  CoachController.new,
);

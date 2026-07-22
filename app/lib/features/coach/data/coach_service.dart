import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../domain/chat_message.dart';
import 'app_check_service.dart';

/// Context sent to the backend so the coach can personalize safely. Contains
/// no direct identifiers beyond the auth token used at the transport layer.
class CoachContext {
  const CoachContext({
    required this.dietId,
    required this.calorieTarget,
    required this.allergies,
    required this.goal,
    required this.requiresProfessionalGuidance,
    required this.historyEnabled,
  });

  final String dietId;
  final int calorieTarget;
  final List<String> allergies;
  final String goal;
  final bool requiresProfessionalGuidance;
  final bool historyEnabled;

  Map<String, dynamic> toJson() => {
    'dietId': dietId,
    'calorieTarget': calorieTarget,
    'allergies': allergies,
    'goal': goal,
    'requiresProfessionalGuidance': requiresProfessionalGuidance,
    'historyEnabled': historyEnabled,
  };
}

/// One streamed chunk from the coach: either a text delta or a final
/// structured payload.
class CoachChunk {
  const CoachChunk.delta(this.textDelta) : structured = null, isFinal = false;
  const CoachChunk.result(this.structured) : textDelta = null, isFinal = true;

  final String? textDelta;
  final ChatMessage? structured;
  final bool isFinal;
}

class CoachException implements Exception {
  CoachException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// AI Coach boundary. The app never talks to a model vendor directly — all
/// requests go through the NutriGuide backend, which holds provider
/// credentials, runs the authoritative safety layer, performs retrieval
/// grounding, and enforces rate/cost limits (master requirement §3, §8).
abstract class CoachService {
  Stream<CoachChunk> ask({
    required String question,
    required CoachContext context,
    required List<ChatMessage> history,
    required String? authToken,
  });
}

/// Production coach client. Streams NDJSON from the backend AI endpoint.
class BackendCoachService implements CoachService {
  BackendCoachService({Dio? dio, String? baseUrl, AppCheckService? appCheck})
    : _dio = dio ?? Dio(),
      _baseUrl = baseUrl ?? AppEnvironment.backendBaseUrl,
      _appCheck = appCheck ?? defaultAppCheckService();

  final Dio _dio;
  final String _baseUrl;
  final AppCheckService _appCheck;

  @override
  Stream<CoachChunk> ask({
    required String question,
    required CoachContext context,
    required List<ChatMessage> history,
    required String? authToken,
  }) async* {
    if (_baseUrl.isEmpty) {
      throw CoachException('The AI Coach backend is not configured.');
    }
    // Firebase App Check token: the backend rejects Coach calls without a
    // valid X-Firebase-AppCheck header (blocks automated abuse).
    final appCheckToken = await _appCheck.token();
    final headers = <String, String>{
      if (authToken != null) 'Authorization': 'Bearer $authToken',
      'X-Firebase-AppCheck': ?appCheckToken,
    };
    final response = await _dio.post<ResponseBody>(
      '$_baseUrl/coach/ask',
      data: {
        'question': question,
        'context': context.toJson(),
        'history': history
            .where((m) => m.role != ChatRole.system)
            .map((m) => {'role': m.role.name, 'text': m.text})
            .toList(),
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: headers.isEmpty ? null : headers,
      ),
    );
    final stream = response.data;
    if (stream == null) {
      throw CoachException('No response from the AI Coach.');
    }
    // The backend emits newline-delimited JSON events; parsing is delegated
    // to the repository which owns the JSON model. Here we surface raw lines
    // as deltas and rely on the repository to assemble the final message.
    var buffer = '';
    await for (final bytes in stream.stream) {
      buffer += String.fromCharCodes(bytes);
      var newline = buffer.indexOf('\n');
      while (newline >= 0) {
        final line = buffer.substring(0, newline).trim();
        buffer = buffer.substring(newline + 1);
        if (line.isNotEmpty) {
          yield CoachChunk.delta(line);
        }
        newline = buffer.indexOf('\n');
      }
    }
    if (buffer.trim().isNotEmpty) {
      yield CoachChunk.delta(buffer.trim());
    }
  }
}

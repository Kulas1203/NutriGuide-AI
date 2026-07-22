import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_ai/features/coach/data/app_check_service.dart';
import 'package:nutriguide_ai/features/coach/data/coach_service.dart';

/// Captures the outgoing request and returns a one-line NDJSON stream so the
/// coach service can be exercised without a real backend.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    final line = '${jsonEncode({'type': 'final', 'text': 'ok'})}\n';
    return ResponseBody.fromString(
      line,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/x-ndjson'],
      },
    );
  }
}

const _context = CoachContext(
  dietId: 'balanced',
  calorieTarget: 2000,
  allergies: [],
  goal: 'Balanced',
  requiresProfessionalGuidance: false,
  historyEnabled: false,
);

void main() {
  group('AppCheckService', () {
    test('NoopAppCheckService never returns a token', () async {
      expect(await const NoopAppCheckService().token(), isNull);
    });

    test('DebugAppCheckService returns the configured token', () async {
      expect(await const DebugAppCheckService('debug-123').token(), 'debug-123');
    });

    test('DebugAppCheckService treats an empty token as no token', () async {
      expect(await const DebugAppCheckService('').token(), isNull);
    });
  });

  group('BackendCoachService header wiring', () {
    Future<RequestOptions> capture(AppCheckService appCheck) async {
      final dio = Dio();
      final adapter = _CapturingAdapter();
      dio.httpClientAdapter = adapter;
      final service = BackendCoachService(
        dio: dio,
        baseUrl: 'https://backend.example',
        appCheck: appCheck,
      );
      await service
          .ask(
            question: 'How much protein?',
            context: _context,
            history: const [],
            authToken: 'id-token-abc',
          )
          .drain<void>();
      return adapter.captured!;
    }

    test('sends the App Check token in X-Firebase-AppCheck', () async {
      final req = await capture(const DebugAppCheckService('appcheck-xyz'));
      expect(req.headers['X-Firebase-AppCheck'], 'appcheck-xyz');
      expect(req.headers['Authorization'], 'Bearer id-token-abc');
    });

    test('omits the App Check header when no token is available', () async {
      final req = await capture(const NoopAppCheckService());
      expect(req.headers.containsKey('X-Firebase-AppCheck'), isFalse);
      expect(req.headers['Authorization'], 'Bearer id-token-abc');
    });
  });
}

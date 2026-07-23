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

/// Returns a canned App Check exchange response, capturing the request.
class _ExchangeAdapter implements HttpClientAdapter {
  _ExchangeAdapter(this.body);

  final Map<String, dynamic> body;
  RequestOptions? captured;
  int calls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    calls++;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

/// Fixed-token stub for the coach header wiring tests.
class _StubAppCheck implements AppCheckService {
  const _StubAppCheck(this._token);
  final String? _token;
  @override
  Future<String?> token() async => _token;
}

const _context = CoachContext(
  dietId: 'balanced',
  calorieTarget: 2000,
  allergies: [],
  goal: 'Balanced',
  requiresProfessionalGuidance: false,
  historyEnabled: false,
);

Dio _dioWith(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

DebugAppCheckService _debugService(Dio dio) => DebugAppCheckService(
  debugToken: 'debug-uuid',
  appId: '1:123:web:abc',
  projectNumber: '123',
  apiKey: 'AIzaKey',
  dio: dio,
);

void main() {
  group('AppCheckService', () {
    test('NoopAppCheckService never returns a token', () async {
      expect(await const NoopAppCheckService().token(), isNull);
    });

    test('DebugAppCheckService exchanges the debug token', () async {
      final adapter = _ExchangeAdapter({'token': 'real-appcheck-jwt', 'ttl': '3600s'});
      final token = await _debugService(_dioWith(adapter)).token();
      expect(token, 'real-appcheck-jwt');
      // Hits Firebase's exchangeDebugToken endpoint with the API key.
      expect(
        adapter.captured!.uri.toString(),
        contains('projects/123/apps/1:123:web:abc:exchangeDebugToken'),
      );
      expect(adapter.captured!.uri.queryParameters['key'], 'AIzaKey');
      expect(adapter.captured!.data, {'debugToken': 'debug-uuid'});
    });

    test('caches the exchanged token instead of re-exchanging', () async {
      final adapter = _ExchangeAdapter({'token': 'jwt', 'ttl': '3600s'});
      final service = _debugService(_dioWith(adapter));
      await service.token();
      await service.token();
      expect(adapter.calls, 1);
    });

    test('returns null when not fully configured', () async {
      final service = DebugAppCheckService(
        debugToken: 'debug-uuid',
        appId: '',
        projectNumber: '123',
        apiKey: 'AIzaKey',
      );
      expect(await service.token(), isNull);
    });
  });

  group('BackendCoachService header wiring', () {
    Future<RequestOptions> capture(AppCheckService appCheck) async {
      final adapter = _CapturingAdapter();
      final service = BackendCoachService(
        dio: _dioWith(adapter),
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
      final req = await capture(const _StubAppCheck('appcheck-xyz'));
      expect(req.headers['X-Firebase-AppCheck'], 'appcheck-xyz');
      expect(req.headers['Authorization'], 'Bearer id-token-abc');
    });

    test('posts to the coachAsk function endpoint', () async {
      final req = await capture(const _StubAppCheck(null));
      expect(req.uri.toString(), 'https://backend.example/coachAsk');
    });

    test('omits the App Check header when no token is available', () async {
      final req = await capture(const _StubAppCheck(null));
      expect(req.headers.containsKey('X-Firebase-AppCheck'), isFalse);
      expect(req.headers['Authorization'], 'Bearer id-token-abc');
    });
  });
}

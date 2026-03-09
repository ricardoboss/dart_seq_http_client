import 'dart:convert';
import 'dart:io';

import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

http.Response _jsonResponse(
  int statusCode, {
  String? minimumLevelAccepted,
  String? error,
}) {
  return http.Response(
    jsonEncode({
      if (minimumLevelAccepted != null)
        'MinimumLevelAccepted': minimumLevelAccepted,
      if (error != null) 'Error': error,
    }),
    statusCode,
  );
}

void main() {
  group('SeqHttpClient', () {
    group('constructor', () {
      test('asserts host is not empty', () {
        expect(() => SeqHttpClient(host: ''), throwsA(isA<AssertionError>()));
      });

      test('asserts host starts with http', () {
        expect(
          () => SeqHttpClient(host: 'ftp://example.com'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts http host', () {
        final client = SeqHttpClient(host: 'http://localhost:5341');
        expect(client, isNotNull);
      });

      test('accepts https host', () {
        final client = SeqHttpClient(host: 'https://seq.example.com');
        expect(client, isNotNull);
      });

      test('asserts apiKey is not empty when provided', () {
        expect(
          () => SeqHttpClient(host: 'http://localhost', apiKey: ''),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts maxRetries >= 0', () {
        expect(
          () => SeqHttpClient(host: 'http://localhost', maxRetries: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('minimumLevelAccepted is initially null', () {
        final client = SeqHttpClient(host: 'http://localhost');
        expect(client.minimumLevelAccepted, isNull);
      });
    });

    group('sendEvents', () {
      test('returns empty list for empty events', () async {
        final client = SeqHttpClient(host: 'http://localhost:5341');
        final results = await client.sendEvents([]);

        expect(results, isEmpty);
      });

      test('sends events and returns all-success on 201', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/api/events/raw');
          expect(
            request.headers['Content-Type'],
            'application/vnd.serilog.clef',
          );

          return _jsonResponse(201);
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
        );

        final results = await client.sendEvents([
          SeqEvent.info('test message'),
        ]);

        expect(results, hasLength(1));
        expect(results.first.isSuccess, isTrue);
      });

      test('updates minimumLevelAccepted on 201', () async {
        final mockClient = MockClient(
          (_) async => _jsonResponse(201, minimumLevelAccepted: 'Warning'),
        );

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
        );

        expect(client.minimumLevelAccepted, isNull);

        await client.sendEvents([SeqEvent.info('test')]);

        expect(client.minimumLevelAccepted, 'Warning');
      });

      test('includes X-Seq-ApiKey header when apiKey is provided', () async {
        final mockClient = MockClient((request) async {
          expect(request.headers['X-Seq-ApiKey'], 'my-api-key');

          return _jsonResponse(201);
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          apiKey: 'my-api-key',
          httpClient: mockClient,
        );

        await client.sendEvents([SeqEvent.info('test')]);
      });

      final errorCases = {
        400: 'malformed',
        401: 'Authorization is required',
        403: 'ingestion permission',
        413: 'maximum size',
        500: 'internal error',
        503: 'starting up',
      };

      for (final entry in errorCases.entries) {
        test('throws SeqHttpClientException on ${entry.key}', () async {
          final mockClient = MockClient(
            (_) async => _jsonResponse(entry.key, error: 'error details'),
          );

          final client = SeqHttpClient(
            host: 'http://localhost:5341',
            httpClient: mockClient,
          );

          expect(
            () => client.sendEvents([SeqEvent.info('test')]),
            throwsA(
              isA<SeqHttpClientException>().having(
                (e) => e.message,
                'message',
                contains(entry.value),
              ),
            ),
          );
        });
      }

      test('throws FormatException on non-JSON response body', () async {
        final mockClient = MockClient(
          (_) async => http.Response('not json', 201),
        );

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
        );

        expect(
          () => client.sendEvents([SeqEvent.info('test')]),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws SeqHttpClientException when body is JSON array', () async {
        final mockClient = MockClient((_) async => http.Response('[]', 201));

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
        );

        expect(
          () => client.sendEvents([SeqEvent.info('test')]),
          throwsA(
            isA<SeqHttpClientException>().having(
              (e) => e.message,
              'message',
              contains('not a JSON object'),
            ),
          ),
        );
      });

      test('retries on network error up to maxRetries', () async {
        var requestCount = 0;

        final mockClient = MockClient((_) async {
          requestCount++;
          throw const SocketException('Connection refused');
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
          maxRetries: 3,
          backoff: (_) => Duration.zero,
        );

        try {
          await client.sendEvents([SeqEvent.info('test')]);
          fail('Expected SeqClientException');
        } on SeqClientException catch (e) {
          expect(e.message, 'Failed to send request');
          expect(e.innerException, isA<SocketException>());
        }

        expect(requestCount, 3);
      });

      test('backoff is called with correct tries count', () async {
        final backoffCalls = <int>[];

        final mockClient = MockClient((_) async {
          throw const SocketException('Connection refused');
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
          maxRetries: 3,
          backoff: (tries) {
            backoffCalls.add(tries);

            return Duration.zero;
          },
        );

        try {
          await client.sendEvents([SeqEvent.info('test')]);
        } on SeqClientException {
          // expected
        }

        expect(backoffCalls, [0, 1, 2]);
      });

      test('does not retry on 400 error response with single event', () async {
        var requestCount = 0;

        final mockClient = MockClient((_) async {
          requestCount++;

          return _jsonResponse(400, error: 'bad request');
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
          maxRetries: 3,
          backoff: (_) => Duration.zero,
        );

        try {
          await client.sendEvents([SeqEvent.info('test')]);
        } on SeqHttpClientException {
          // expected
        }

        expect(requestCount, 1);
      });

      test('succeeds after transient failure then 201', () async {
        var requestCount = 0;

        final mockClient = MockClient((_) async {
          requestCount++;
          if (requestCount == 1) {
            throw const SocketException('Connection refused');
          }

          return _jsonResponse(201);
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
          maxRetries: 3,
          backoff: (_) => Duration.zero,
        );

        await client.sendEvents([SeqEvent.info('test')]);

        expect(requestCount, 2);
      });
    });

    group('per-event retry on batch 400', () {
      test(
        'retries individually when batch returns 400 with multiple events',
        () async {
          var batchRequestSent = false;
          var individualRequests = 0;

          final mockClient = MockClient((request) async {
            final body = request.body;
            final isMultiEvent = body.contains('\n');

            if (isMultiEvent && !batchRequestSent) {
              batchRequestSent = true;
              return _jsonResponse(400, error: 'batch malformed');
            }

            individualRequests++;
            return _jsonResponse(201);
          });

          final client = SeqHttpClient(
            host: 'http://localhost:5341',
            httpClient: mockClient,
          );

          final events = [SeqEvent.info('good1'), SeqEvent.info('good2')];
          final results = await client.sendEvents(events);

          expect(batchRequestSent, isTrue);
          expect(individualRequests, 2);
          expect(results, hasLength(2));
          expect(results.every((r) => r.isSuccess), isTrue);
        },
      );

      test(
        'returns mixed results when one event is rejected individually',
        () async {
          var batchRequestSent = false;
          var individualRequestIndex = 0;

          final mockClient = MockClient((request) async {
            final body = request.body;
            final isMultiEvent = body.contains('\n');

            if (isMultiEvent && !batchRequestSent) {
              batchRequestSent = true;
              return _jsonResponse(400, error: 'batch malformed');
            }

            individualRequestIndex++;
            // Second individual event is rejected
            if (individualRequestIndex == 2) {
              return _jsonResponse(400, error: 'bad event');
            }
            return _jsonResponse(201);
          });

          final client = SeqHttpClient(
            host: 'http://localhost:5341',
            httpClient: mockClient,
          );

          final events = [SeqEvent.info('good'), SeqEvent.info('bad')];
          final results = (await client.sendEvents(events)).toList();

          expect(results, hasLength(2));
          expect(results[0].isSuccess, isTrue);
          expect(results[1].isSuccess, isFalse);
          expect(results[1].isPermanent, isTrue);
          expect(results[1].error, isA<SeqHttpClientException>());
        },
      );

      test('handles network error during individual retry', () async {
        var batchRequestSent = false;

        final mockClient = MockClient((request) async {
          final body = request.body;
          final isMultiEvent = body.contains('\n');

          if (isMultiEvent && !batchRequestSent) {
            batchRequestSent = true;
            return _jsonResponse(400, error: 'batch malformed');
          }

          if (body.contains('network-fail')) {
            throw const SocketException('Connection lost');
          }
          return _jsonResponse(201);
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
          backoff: (_) => Duration.zero,
        );

        final events = [SeqEvent.info('good'), SeqEvent.info('network-fail')];
        final results = (await client.sendEvents(events)).toList();

        expect(results, hasLength(2));
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isFalse);
        expect(results[1].isPermanent, isFalse);
        expect(results[1].error, isA<SocketException>());
      });

      test(
        'marks non-400 HTTP error as transient during individual retry',
        () async {
          var batchRequestSent = false;
          var individualRequestIndex = 0;

          final mockClient = MockClient((request) async {
            final body = request.body;
            final isMultiEvent = body.contains('\n');

            if (isMultiEvent && !batchRequestSent) {
              batchRequestSent = true;
              return _jsonResponse(400, error: 'batch malformed');
            }

            individualRequestIndex++;
            if (individualRequestIndex == 2) {
              return _jsonResponse(500, error: 'server error');
            }
            return _jsonResponse(201);
          });

          final client = SeqHttpClient(
            host: 'http://localhost:5341',
            httpClient: mockClient,
          );

          final events = [SeqEvent.info('good'), SeqEvent.info('server-fail')];
          final results = (await client.sendEvents(events)).toList();

          expect(results, hasLength(2));
          expect(results[0].isSuccess, isTrue);
          expect(results[1].isSuccess, isFalse);
          expect(results[1].isPermanent, isFalse);
          expect(results[1].error, isA<SeqHttpClientException>());
        },
      );

      test('does not retry individually on 400 with single event', () async {
        final mockClient = MockClient(
          (_) async => _jsonResponse(400, error: 'bad request'),
        );

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
        );

        expect(
          () => client.sendEvents([SeqEvent.info('test')]),
          throwsA(isA<SeqHttpClientException>()),
        );
      });

      test('does not retry individually on 401 with multiple events', () async {
        final mockClient = MockClient(
          (_) async => _jsonResponse(401, error: 'unauthorized'),
        );

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
        );

        expect(
          () => client.sendEvents([SeqEvent.info('one'), SeqEvent.info('two')]),
          throwsA(isA<SeqHttpClientException>()),
        );
      });

      test(
        'updates minimumLevelAccepted from individual retry responses',
        () async {
          var batchRequestSent = false;

          final mockClient = MockClient((request) async {
            final body = request.body;
            final isMultiEvent = body.contains('\n');

            if (isMultiEvent && !batchRequestSent) {
              batchRequestSent = true;
              return _jsonResponse(400, error: 'batch malformed');
            }

            return _jsonResponse(201, minimumLevelAccepted: 'Error');
          });

          final client = SeqHttpClient(
            host: 'http://localhost:5341',
            httpClient: mockClient,
          );

          final results = await client.sendEvents([
            SeqEvent.info('one'),
            SeqEvent.info('two'),
          ]);

          expect(results, hasLength(2));
          expect(results.every((r) => r.isSuccess), isTrue);
          expect(client.minimumLevelAccepted, 'Error');
        },
      );
    });

    group('event serialization', () {
      test(
        'sends events as newline-delimited JSON in reversed order',
        () async {
          String? capturedBody;

          final mockClient = MockClient((request) async {
            capturedBody = request.body;

            return _jsonResponse(201);
          });

          final client = SeqHttpClient(
            host: 'http://localhost:5341',
            httpClient: mockClient,
          );

          final events = [
            SeqEvent(
              timestamp: DateTime.utc(2024),
              message: 'first',
              level: 'Information',
            ),
            SeqEvent(
              timestamp: DateTime.utc(2024, 1, 2),
              message: 'second',
              level: 'Warning',
            ),
          ];

          await client.sendEvents(events);

          expect(capturedBody, isNotNull);
          final lines = capturedBody!.split('\n');
          expect(lines, hasLength(2));

          final firstLine = jsonDecode(lines[0]) as Map<String, dynamic>;
          final secondLine = jsonDecode(lines[1]) as Map<String, dynamic>;
          expect(firstLine['@m'], 'second');
          expect(secondLine['@m'], 'first');
        },
      );

      test('each line in request body is valid JSON', () async {
        String? capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = request.body;

          return _jsonResponse(201);
        });

        final client = SeqHttpClient(
          host: 'http://localhost:5341',
          httpClient: mockClient,
        );

        await client.sendEvents([
          SeqEvent.info('msg1'),
          SeqEvent.warning('msg2'),
          SeqEvent.error('msg3'),
        ]);

        expect(capturedBody, isNotNull);
        for (final line in capturedBody!.split('\n')) {
          expect(() => jsonDecode(line), returnsNormally);
        }
      });
    });
  });

  group('linearBackoff', () {
    test('returns 0ms for 0 tries', () {
      expect(linearBackoff(0), Duration.zero);
    });

    test('returns 100ms for 1 try', () {
      expect(linearBackoff(1), const Duration(milliseconds: 100));
    });

    test('returns 500ms for 5 tries', () {
      expect(linearBackoff(5), const Duration(milliseconds: 500));
    });

    test('increases linearly', () {
      final d1 = linearBackoff(1);
      final d2 = linearBackoff(2);
      final d3 = linearBackoff(3);

      expect(d2 - d1, d1);
      expect(d3 - d2, d1);
    });
  });
}

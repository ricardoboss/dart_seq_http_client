import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('SeqHttpClientException', () {
    test('extends SeqClientException', () {
      final exception = SeqHttpClientException('test');

      expect(exception, isA<SeqClientException>());
      expect(exception, isA<Exception>());
    });

    test('stores message', () {
      final exception = SeqHttpClientException('error occurred');

      expect(exception.message, 'error occurred');
    });

    test('stores response when provided', () {
      final response = http.Response('body', 400);
      final exception = SeqHttpClientException(
        'bad request',
        response: response,
      );

      expect(exception.response, isNotNull);
      expect(exception.response!.statusCode, 400);
    });

    test('response is null when not provided', () {
      final exception = SeqHttpClientException('no response');

      expect(exception.response, isNull);
    });

    test('stores inner exception and stack trace', () {
      final inner = Exception('root');
      final stack = StackTrace.current;

      final exception = SeqHttpClientException(
        'wrapper',
        innerException: inner,
        innerStackTrace: stack,
      );

      expect(exception.innerException, inner);
      expect(exception.innerStackTrace, stack);
    });

    test('toString includes message', () {
      final exception = SeqHttpClientException('http error');

      expect(exception.toString(), contains('http error'));
      expect(exception.toString(), contains('SeqHttpClientException'));
    });

    test('toString includes status code and body when response is present', () {
      final response = http.Response(
        '{"Error":"@tr trace id too long"}',
        400,
      );
      final exception = SeqHttpClientException(
        'bad request',
        response: response,
      );

      final str = exception.toString();
      expect(str, contains('statusCode: 400'));
      expect(str, contains('@tr trace id too long'));
    });

    test('toString includes innerException when present', () {
      final exception = SeqHttpClientException(
        'wrapper',
        innerException: Exception('root cause'),
      );

      expect(exception.toString(), contains('innerException:'));
      expect(exception.toString(), contains('root cause'));
    });

    group('isRetryable', () {
      test('returns true when response is null', () {
        final exception = SeqHttpClientException('network error');

        expect(exception.isRetryable, isTrue);
      });

      test('returns false for 413 Payload Too Large', () {
        final response = http.Response('too large', 413);
        final exception = SeqHttpClientException(
          'payload too large',
          response: response,
        );

        expect(exception.isRetryable, isFalse);
      });

      test('returns false for 400 Bad Request', () {
        final response = http.Response('bad request', 400);
        final exception = SeqHttpClientException(
          'bad request',
          response: response,
        );

        expect(exception.isRetryable, isFalse);
      });

      test('returns true for 500 Internal Server Error', () {
        final response = http.Response('server error', 500);
        final exception = SeqHttpClientException(
          'server error',
          response: response,
        );

        expect(exception.isRetryable, isTrue);
      });

      test('returns true for 503 Service Unavailable', () {
        final response = http.Response('unavailable', 503);
        final exception = SeqHttpClientException(
          'unavailable',
          response: response,
        );

        expect(exception.isRetryable, isTrue);
      });

      test('returns true for 429 Too Many Requests', () {
        final response = http.Response('rate limited', 429);
        final exception = SeqHttpClientException(
          'rate limited',
          response: response,
        );

        expect(exception.isRetryable, isTrue);
      });
    });
  });
}

import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('SeqHttpClientException', () {
    test('isRetryable returns false for 400 and 413 status codes', () {
      final exception400 = SeqHttpClientException(
        'Bad Request',
        response: http.Response('Bad Request', 400),
      );
      final exception413 = SeqHttpClientException(
        'Payload Too Large',
        response: http.Response('Payload Too Large', 413),
      );

      expect(exception400.isRetryable, isFalse);
      expect(exception413.isRetryable, isFalse);
    });

    test('isRetryable returns true for other status codes', () {
      // Common other status codes
      final otherStatusCodes = [200, 201, 203, 204, 405, 500, 502, 503];
      for (final code in otherStatusCodes) {
        final exception = SeqHttpClientException(
          'Error $code',
          response: http.Response('Error $code', code),
        );
        expect(
          exception.isRetryable,
          isTrue,
          reason: 'Expected status code $code to be retryable',
        );
      }
    });

    test('isRetryable returns true when response is null', () {
      final exception = SeqHttpClientException('No response');
      expect(exception.isRetryable, isTrue);
    });
  });
}

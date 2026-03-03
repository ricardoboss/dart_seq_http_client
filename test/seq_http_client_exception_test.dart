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

    test('toString includes message from parent', () {
      final exception = SeqHttpClientException('http error');

      expect(exception.toString(), contains('http error'));
      expect(exception.toString(), contains('SeqClientException'));
    });
  });
}

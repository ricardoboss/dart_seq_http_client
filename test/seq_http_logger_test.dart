import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('SeqHttpLogger', () {
    test('create() returns a SeqLogger', () {
      final logger = SeqHttpLogger.create(host: 'https://localhost');

      expect(logger, isA<SeqLogger>());
    });

    test('create() uses SeqInMemoryCache by default', () {
      final logger = SeqHttpLogger.create(host: 'https://localhost');

      expect(logger.cache, isA<SeqInMemoryCache>());
    });

    test('create() uses custom cache when provided', () {
      final customCache = SeqInMemoryCache();
      final logger = SeqHttpLogger.create(
        host: 'https://localhost',
        cache: customCache,
      );

      expect(logger.cache, same(customCache));
    });

    test('create() passes backlogLimit through', () {
      final logger = SeqHttpLogger.create(
        host: 'https://localhost',
        backlogLimit: 100,
      );

      expect(logger.backlogLimit, 100);
    });

    test('create() passes globalContext through', () {
      final context = {'app': 'test'};
      final logger = SeqHttpLogger.create(
        host: 'https://localhost',
        globalContext: context,
      );

      expect(logger.globalContext, same(context));
    });

    test('create() passes minimumLogLevel through', () {
      final logger = SeqHttpLogger.create(
        host: 'https://localhost',
        minimumLogLevel: 'Warning',
      );

      expect(logger.minimumLogLevel, 'Warning');
    });

    test('create() passes autoFlush through', () {
      final logger = SeqHttpLogger.create(
        host: 'https://localhost',
        autoFlush: false,
      );

      expect(logger.autoFlush, isFalse);
    });

    test('create() uses SeqHttpClient as client', () {
      final logger = SeqHttpLogger.create(host: 'https://localhost');

      expect(logger.client, isA<SeqHttpClient>());
    });

    test('create() defaults backlogLimit to 50', () {
      final logger = SeqHttpLogger.create(host: 'https://localhost');

      expect(logger.backlogLimit, 50);
    });

    test('create() defaults autoFlush to true', () {
      final logger = SeqHttpLogger.create(host: 'https://localhost');

      expect(logger.autoFlush, isTrue);
    });

    test('create() passes throwOnError through', () {
      final logger = SeqHttpLogger.create(
        host: 'https://localhost',
        throwOnError: true,
      );

      expect(logger.throwOnError, isTrue);
    });

    test('create() defaults throwOnError to false', () {
      final logger = SeqHttpLogger.create(host: 'https://localhost');

      expect(logger.throwOnError, isFalse);
    });

    test('create() accepts httpClient parameter', () async {
      var requestReceived = false;
      final mockClient = MockClient((request) async {
        requestReceived = true;
        return http.Response('{}', 201);
      });
      final logger = SeqHttpLogger.create(
        host: 'https://localhost',
        httpClient: mockClient,
        autoFlush: false,
      );

      await logger.log(SeqLogLevel.information, 'test');
      await logger.flush();

      expect(requestReceived, isTrue);
    });
  });
}

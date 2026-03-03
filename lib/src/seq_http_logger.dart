import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:http/http.dart' as http;

class SeqHttpLogger {
  /// Creates a new instance of [SeqLogger] that logs to a Seq server over HTTP.
  ///
  /// This method is a factory for creating a new instance of [SeqLogger] that
  /// logs to a Seq server over HTTP using the [SeqHttpClient].
  ///
  /// By default, a new instance of [SeqInMemoryCache] is used for caching the
  /// events. If you want to use a different cache, you can pass it as the
  /// [cache] parameter.
  static SeqLogger create({
    required String host,
    String? apiKey,
    int maxRetries = 5,
    SeqCache? cache,
    int backlogLimit = 50,
    SeqContext? globalContext,
    String? minimumLogLevel,
    bool autoFlush = true,
    bool throwOnError = false,
    Duration? flushInterval,
    FlushErrorHandler? onFlushError,
    void Function(SeqEvent event)? onDiagnosticLog,
    Duration Function(int tries)? httpBackoff,
    http.Client? httpClient,
  }) {
    if (onDiagnosticLog != null) {
      SeqLogger.onDiagnosticLog = onDiagnosticLog;
    }
    final seqHttpClient = SeqHttpClient(
      host: host,
      apiKey: apiKey,
      maxRetries: maxRetries,
      backoff: httpBackoff,
      httpClient: httpClient,
    );

    final actualCache = cache ?? SeqInMemoryCache();

    return SeqLogger(
      client: seqHttpClient,
      cache: actualCache,
      backlogLimit: backlogLimit,
      globalContext: globalContext,
      minimumLogLevel: minimumLogLevel,
      autoFlush: autoFlush,
      throwOnError: throwOnError,
      flushInterval: flushInterval,
      onFlushError: onFlushError,
    );
  }
}

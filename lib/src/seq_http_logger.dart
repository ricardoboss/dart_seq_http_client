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
  ///
  /// When [throwOnError] is `true`, exceptions during flush propagate to the
  /// caller instead of being silently caught. Defaults to `false`.
  ///
  /// When [onFlushError] is set, it is called with per-event results on flush
  /// failure. See [FlushErrorHandler] for details.
  ///
  /// The [httpBackoff] function controls retry delay between failed HTTP
  /// requests. Defaults to linear backoff (100ms * attempt).
  ///
  /// Pass a custom [httpClient] to control the underlying HTTP transport
  /// (useful for testing or custom TLS configuration).
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
    FlushErrorHandler? onFlushError,
    Duration Function(int tries)? httpBackoff,
    http.Client? httpClient,
  }) {
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
      onFlushError: onFlushError,
    );
  }
}

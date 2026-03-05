// ignore_for_file: avoid_print

import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';

Future<List<SeqEvent>> _handleFlushError(
  Iterable<SeqEventResult> results,
  Object error,
) async {
  final toRetry = <SeqEvent>[];

  for (final r in results.where((r) => !r.isSuccess)) {
    if (r.isPermanent) {
      // Event is malformed (e.g. HTTP 400) - retrying would fail again.
      print('Dropping permanently rejected event: ${r.error}');
      continue;
    }
    // Transient failure (network, server overload) - retry.
    toRetry.add(r.event);
  }

  print('Flush error: $error');
  print('Retrying ${toRetry.length} of ${results.length} events');
  return toRetry;
}

/// Run a local Seq instance first:
///   docker compose up -d
///
/// Then run this example:
///   dart run example/main.dart
///
/// Open http://localhost:80 to view the logged events.
Future<void> main() async {
  // ── Diagnostic logging ──────────────────────────────────────────────
  // Observe internal diagnostics from the logger (useful for debugging).
  SeqLogger.onDiagnosticLog = (event) {
    final msg = event.message ?? event.messageTemplate;
    print('[diagnostic] ${event.level}: $msg');
  };

  // ── Create logger ───────────────────────────────────────────────────
  final logger = SeqHttpLogger.create(
    host: 'http://localhost:5341',
    backlogLimit: 10,
    globalContext: {
      'App': 'dart_seq_example',
      'Environment': 'development',
    },
    onFlushError: _handleFlushError,
  );

  // ── Log levels ──────────────────────────────────────────────────────
  await logger.verbose('Application starting up');
  await logger.debug('Loading configuration');
  await logger.info('Server listening on port {Port}', context: {'Port': 8080});
  await logger.warning(
    'Cache miss rate is {Rate}%',
    context: {'Rate': 87.5},
  );

  // ── Errors with exceptions ──────────────────────────────────────────
  try {
    throw const FormatException('unexpected token at position 42');
  } on FormatException catch (e) {
    await logger.error(
      'Failed to parse config file {File}',
      exception: e,
      context: {'File': 'config.yaml'},
    );
  }

  await logger.fatal(
    'Unrecoverable error in {Component}',
    exception: StateError('connection pool exhausted'),
    context: {'Component': 'DatabaseService'},
  );

  // ── Custom properties & structured data ─────────────────────────────
  await logger.log(
    SeqLogLevel.information,
    'User {UserId} performed {Action}',
    context: {
      'UserId': 'usr_123',
      'Action': 'login',
      'IpAddress': '192.168.1.100',
      'UserAgent': 'DartApp/1.0',
    },
  );

  await logger.log(
    SeqLogLevel.information,
    'Order {OrderId} placed with {ItemCount} items',
    context: {
      'OrderId': 'ord_456',
      'ItemCount': 3,
      'TotalAmount': 59.99,
      'Items': ['Widget A', 'Widget B', 'Gadget C'],
    },
  );

  // ── Distributed tracing properties ──────────────────────────────────
  await logger.log(
    SeqLogLevel.information,
    'Processing request {RequestPath}',
    context: {'RequestPath': '/api/users/123'},
    traceId: 'abc123def456abc123def456abc12345',
    spanId: 'abc123def4560001',
    parentSpanId: 'abc123def4560000',
    spanStart: DateTime.now().toUtc(),
    scope: 'HttpServer',
    spanKind: 'Server',
    resourceAttributes: {
      'service.name': 'user-api',
      'service.version': '2.1.0',
    },
  );

  // ── Flush remaining events ──────────────────────────────────────────
  await logger.flush();

  print('Done! Open http://localhost:80 to view events in Seq.');
}

![GitHub License](https://img.shields.io/github/license/ricardoboss/dart_seq_http_client)
![Pub Version](https://img.shields.io/pub/v/dart_seq_http_client)
![Pub Points](https://img.shields.io/pub/points/dart_seq_http_client)
![Pub Likes](https://img.shields.io/pub/likes/dart_seq_http_client)
![Pub Popularity](https://img.shields.io/pub/popularity/dart_seq_http_client)

`dart_seq_http_client` is a HTTP client implementation for `dart_seq`, enabling you to send log
entries to a Seq server using HTTP ingestion.

## Features

Additionally to the features provided by `dart_seq`, `dart_seq_http_client` offers:

- **Automatic Retry Mechanism**: The library automatically retries failed requests to the Seq server with configurable backoff. Non-retryable status codes (400, 401, 403, 413, 429, 500) are not retried at the batch level.
- **Per-Event Error Isolation**: When a batch is rejected with HTTP 400, the client automatically retries each event individually to isolate malformed events. Valid events are delivered; only the bad ones fail.
- **Minimum Log Level Enforcement**: `dart_seq_http_client` keeps track of the server-side configured minimum log level and discards events that fall below this threshold. This feature helps reduce unnecessary log entries and ensures that only relevant and significant events are forwarded to the Seq server.

## Getting Started

To start using `dart_seq_http_client` in your Dart/Flutter application, follow these steps:

1. Install this library: `dart pub add dart_seq dart_seq_http_client`
2. Instantiate the HTTP client logger (see usage below)
3. Enjoy!

## Usage

After the installation, you can use the library like this:

```dart
import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';

Future<void> main() async {
  // Use the HTTP client implementation to create a logger
  final logger = SeqHttpLogger.create(
    host: 'http://localhost:5341',
    globalContext: {
      'App': 'Example',
    },
  );

  // Log a message
  await logger.log(
    SeqLogLevel.information,
    'test, logged at: {Timestamp}',
    context: {
      'Timestamp': DateTime.now().toUtc().toIso8601String(),
    },
  );

  // Flush the logger to ensure all messages are sent
  await logger.flush();
}
```

See the [`example`](./example) directory for a complete example, including a `docker-compose.yml`
file to start a local Seq instance.

## HTTP Retry Behavior

`SeqHttpClient.sendEvents()` handles server responses as follows:

| Server response | Batch size | Behavior |
|---|---|---|
| **201** | any | Success — returns all `SeqEventSentResult.success` |
| **400** | > 1 | Per-event retry — each event sent individually (see below) |
| **400** | 1 | **Throws** — single event is malformed, can't isolate further |
| **401/403** | any | **Throws** — auth problem, not per-event |
| **413/429/500/503** | any | **Throws** — server problem, not per-event |
| Network error | any | Retries with backoff up to `maxRetries`, then **throws** |

### Per-event retry on batch 400

When a batch of multiple events is rejected with HTTP 400, the client retries each event
individually to isolate the bad ones:

| Individual response | Result |
|---|---|
| 201 | `SeqEventSentResult.success` |
| 400 | `SeqEventSentResult.failure(isPermanent: true)` — event is malformed |
| Other 4xx/5xx | `SeqEventSentResult.failure(isPermanent: false)` — transient |
| Network error | `SeqEventSentResult.failure(isPermanent: false)` — transient |

The `isPermanent` flag tells `SeqLogger.flush()` whether to drop or re-queue the event
(see [`dart_seq` README](https://pub.dev/packages/dart_seq) for flush behavior details).

### End-to-end example

3 events sent in batch, server returns 400, per-event retry finds event #2 is malformed:

```
flush():
  POST batch [1, 2, 3] -> 400
  POST event 1 -> 201 (success)
  POST event 2 -> 400 (isPermanent: true)
  POST event 3 -> 201 (success)

Result: events 1 and 3 delivered, event 2 dropped from cache
```

## Error Handling

By default, logging methods will never throw exceptions — errors during flush are silently caught
and reported via `onDiagnosticLog`. To let exceptions propagate, set `throwOnError: true`:

```dart
final logger = SeqHttpLogger.create(
  host: 'http://localhost:5341',
  throwOnError: true, // exceptions propagate to caller
);
```

When `throwOnError` is `false` (default), you can still observe errors using the `onFlushError`
callback or the diagnostic log:

```dart
// Observe all internal diagnostics
SeqLogger.onDiagnosticLog = (event) {
  print('[dart_seq] ${event.level}: ${event.message ?? event.messageTemplate}');
};
```

The default flush behavior (without `onFlushError`) already handles the common cases:
- Permanent failures (HTTP 400) are dropped
- Transient failures (network, server errors) are re-queued
- Total failures (exception thrown) leave events in cache

Only provide `onFlushError` if you need custom logic (logging, retry limits, etc.):

```dart
final logger = SeqHttpLogger.create(
  host: 'http://localhost:5341',
  onFlushError: (results, error) async {
    final toRetry = <SeqEvent>[];

    for (final r in results.where((r) => !r.isSuccess)) {
      if (r.isPermanent) {
        print('Dropping malformed event: ${r.error}');
        continue;
      }
      toRetry.add(r.event);
    }

    return toRetry;
  },
);
```

### Exception hierarchy

- `SeqClientException` — base exception for all Seq client errors (defined in `dart_seq`)
- `SeqHttpClientException` — HTTP-specific errors with access to the `Response` object
  (defined in `dart_seq_http_client`)

## Additional information

- Feature requests and bug reports should be reported using [GitHub issues](https://github.com/ricardoboss/dart_seq_http_client/issues).
- Contributions are welcome! If you'd like to contribute, please follow the guidelines outlined in the [CONTRIBUTING.md](https://github.com/ricardoboss/dart_seq/blob/main/CONTRIBUTING.md) file.

## License

`dart_seq_http_client` is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.

This project is not affiliated with [Datalust](https://datalust.co/), the creators of Seq. The
library is an independent open-source project developed by the community for the community.

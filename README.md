![GitHub License](https://img.shields.io/github/license/ricardoboss/dart_seq_http_client)
![Pub Version](https://img.shields.io/pub/v/dart_seq_http_client)
![Pub Points](https://img.shields.io/pub/points/dart_seq_http_client)
![Pub Likes](https://img.shields.io/pub/likes/dart_seq_http_client)
![Pub Popularity](https://img.shields.io/pub/popularity/dart_seq_http_client)

`dart_seq_http_client` is a HTTP client implementation for `dart_seq`, enabling you to send log
entries to a Seq server using HTTP ingestion.

## Features

Additionally to the features provided by `dart_seq`, `dart_seq_http_client` offers:

- **Automatic Retry Mechanism**: The library automatically retries failed requests to the Seq server, except in the case of 429 (Too Many Requests) responses. This built-in resilience ensures that log entries are reliably delivered, even in the face of intermittent network connectivity or temporary server unavailability.
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
    null,
    {
      'Timestamp': DateTime.now().toUtc().toIso8601String(),
    },
  );

  // Flush the logger to ensure all messages are sent
  await logger.flush();
}
```

See the [`example`](./example) directory for a complete example, including a `docker-compose.yml`
file to start a local Seq instance.

## Additional information

- Feature requests and bug reports should be reported using [GitHub issues](https://github.com/ricardoboss/dart_seq_http_client/issues).
- Contributions are welcome! If you'd like to contribute, please follow the guidelines outlined in the [CONTRIBUTING.md](https://github.com/ricardoboss/dart_seq/blob/main/CONTRIBUTING.md) file.

## License

`dart_seq_http_client` is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.

This project is not affiliated with [Datalust](https://datalust.co/), the creators of Seq. The
library is an independent open-source project developed by the community for the community.

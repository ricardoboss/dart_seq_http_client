import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';

Future<void> main() async {
  final logger = SeqHttpLogger.create(
    host: 'http://localhost:5341',
    globalContext: {
      'App': 'Example',
    },
  );

  await logger.log(
    SeqLogLevel.information,
    'test, logged at: {Timestamp}',
    null,
    {
      'Timestamp': DateTime.now().toUtc().toIso8601String(),
    },
  );

  await logger.flush();
}

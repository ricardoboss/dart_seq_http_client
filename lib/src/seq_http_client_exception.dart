import 'package:dart_seq/dart_seq.dart';
import 'package:http/http.dart';

class SeqHttpClientException extends SeqClientException {
  SeqHttpClientException(
    String message, {
    Object? innerException,
    StackTrace? innerStackTrace,
    this.response,
  }) : super(message, innerException, innerStackTrace);

  final Response? response;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('SeqHttpClientException: ')
      ..write(message);

    if (response case final Response r) {
      buffer
        ..write('; statusCode: ')
        ..write(r.statusCode)
        ..write('; body: ')
        ..write(r.body);
    }

    if (innerException case final innerExceptionValue?) {
      buffer
        ..write('; innerException: ')
        ..write(innerExceptionValue);
    }

    return buffer.toString();
  }

  /// Non-retryable when the server explicitly rejects the request body.
  ///
  /// - 413 (Payload Too Large) - the batch is too big; resending won't help.
  /// - 400 (Bad Request) - the payload is malformed; resending won't help.
  @override
  bool get isRetryable {
    final code = response?.statusCode;

    return switch (code) {
      413 || 400 => false,
      null => true,
      _ => true,
    };
  }
}

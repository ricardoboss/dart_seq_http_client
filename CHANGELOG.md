## 2.0.0 ([#1](https://github.com/ricardoboss/dart_seq_http_client/pull/1))

* **Breaking:** Requires `dart_seq` 3.0.0 (`sendEvents` returns `Future<List<SeqEventResult>>`)
* **Breaking:** `SeqResponse` constructor now uses named parameters
* Per-event retry on batch 400 - isolates malformed events instead of failing the entire batch
* `SeqHttpClientException.isRetryable` - 400/413 are non-retryable, others retryable
* `SeqHttpClientException.toString()` includes status code and response body
* `SeqHttpLogger.create()` accepts `throwOnError` and `onFlushError` parameters
* README: Error Handling section ([#13](https://github.com/ricardoboss/dart_seq/issues/13)) with exception hierarchy docs

## 1.0.0

* No changes; bump to 1.0.0 release

## 0.0.1-pre.2

* No changes; bump to test release workflow

## 0.0.1-pre.1

* Initial release
* Moved `SeqHttpClient` from `dart_seq`

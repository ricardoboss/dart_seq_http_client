import 'dart:convert';

import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:test/test.dart';

void main() {
  test('Seq Response decoding', () {
    const json =
        '{"MinimumLevelAccepted": "Information", "Error": "test error"}';
    final map = jsonDecode(json) as Map<String, dynamic>;

    final response = SeqResponse.fromJson(map);

    expect(response.minimumLevelAccepted, 'Information');
    expect(response.error, 'test error');
  });
}

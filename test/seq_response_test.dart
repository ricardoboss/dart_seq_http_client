import 'dart:convert';

import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:test/test.dart';

void main() {
  group('SeqResponse', () {
    test('fromJson decodes all fields', () {
      const json =
          '{"MinimumLevelAccepted": "Information", "Error": "test error"}';
      final map = jsonDecode(json) as Map<String, dynamic>;

      final response = SeqResponse.fromJson(map);

      expect(response.minimumLevelAccepted, 'Information');
      expect(response.error, 'test error');
    });

    test('fromJson with missing fields returns nulls', () {
      final response = SeqResponse.fromJson(<String, dynamic>{});

      expect(response.minimumLevelAccepted, isNull);
      expect(response.error, isNull);
    });

    test('fromJson with only MinimumLevelAccepted', () {
      final response = SeqResponse.fromJson({
        'MinimumLevelAccepted': 'Warning',
      });

      expect(response.minimumLevelAccepted, 'Warning');
      expect(response.error, isNull);
    });

    test('fromJson with only Error', () {
      final response = SeqResponse.fromJson({'Error': 'some error'});

      expect(response.minimumLevelAccepted, isNull);
      expect(response.error, 'some error');
    });
  });
}

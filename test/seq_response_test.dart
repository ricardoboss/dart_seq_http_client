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

    test('fromJson with missing MinimumLevelAccepted returns null', () {
      final response = SeqResponse.fromJson({'Error': 'some error'});

      expect(response.minimumLevelAccepted, isNull);
      expect(response.error, 'some error');
    });

    test('fromJson with null MinimumLevelAccepted returns null', () {
      final response = SeqResponse.fromJson({
        'MinimumLevelAccepted': null,
        'Error': 'some error',
      });

      expect(response.minimumLevelAccepted, isNull);
      expect(response.error, 'some error');
    });

    test('fromJson with missing Error returns null', () {
      final response =
          SeqResponse.fromJson({'MinimumLevelAccepted': 'Warning'});

      expect(response.minimumLevelAccepted, 'Warning');
      expect(response.error, isNull);
    });

    test('fromJson with null Error returns null', () {
      final response = SeqResponse.fromJson({
        'MinimumLevelAccepted': 'Warning',
        'Error': null,
      });

      expect(response.minimumLevelAccepted, 'Warning');
      expect(response.error, isNull);
    });

    test('fromJson with empty JSON returns nulls', () {
      final response = SeqResponse.fromJson(<String, dynamic>{});

      expect(response.minimumLevelAccepted, isNull);
      expect(response.error, isNull);
    });

    test('direct constructor stores fields', () {
      final response = SeqResponse('Fatal', 'bad request');

      expect(response.minimumLevelAccepted, 'Fatal');
      expect(response.error, 'bad request');
    });

    test('direct constructor with nulls', () {
      final response = SeqResponse(null, null);

      expect(response.minimumLevelAccepted, isNull);
      expect(response.error, isNull);
    });
  });
}

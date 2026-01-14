import 'package:dart_cloud_email_client_api/dart_cloud_email_client_api.dart';
import 'package:test/test.dart';

void main() {
  group('ListEmailsParams', () {
    test('creates params with all fields', () {
      final params = ListEmailsParams(
        query: 'test query',
        domain: 'example.com',
        sort: '-created_at',
        page: '2',
        limit: '50',
      );

      expect(params.query, equals('test query'));
      expect(params.domain, equals('example.com'));
      expect(params.sort, equals('-created_at'));
      expect(params.page, equals('2'));
      expect(params.limit, equals('50'));
    });

    test('creates params with null fields', () {
      final params = ListEmailsParams();

      expect(params.query, isNull);
      expect(params.domain, isNull);
      expect(params.sort, isNull);
      expect(params.page, isNull);
      expect(params.limit, isNull);
    });

    test('toQueryParameters converts to query map', () {
      final params = ListEmailsParams(
        query: 'test',
        domain: 'example.com',
        sort: '-created_at',
        page: '1',
        limit: '10',
      );

      final queryParams = params.toQueryParameters();

      expect(queryParams['q'], equals('test'));
      expect(queryParams['domain'], equals('example.com'));
      expect(queryParams['sort'], equals('-created_at'));
      expect(queryParams['page'], equals('1'));
      expect(queryParams['limit'], equals('10'));
    });

    test('toQueryParameters excludes null values', () {
      final params = ListEmailsParams(
        query: 'test',
        limit: '10',
      );

      final queryParams = params.toQueryParameters();

      expect(queryParams['q'], equals('test'));
      expect(queryParams['limit'], equals('10'));
      expect(queryParams.containsKey('domain'), isFalse);
      expect(queryParams.containsKey('sort'), isFalse);
      expect(queryParams.containsKey('page'), isFalse);
    });

    test('toQueryParameters returns empty map for all null params', () {
      final params = ListEmailsParams();

      final queryParams = params.toQueryParameters();

      expect(queryParams, isEmpty);
    });
  });
}

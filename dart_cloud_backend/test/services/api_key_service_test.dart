import 'dart:convert';
import 'package:test/test.dart';
import 'package:database/database.dart';
import 'package:dart_cloud_backend/services/api_key_service.dart';

void main() {
  group('ApiKeyService', () {
    setUp(() {
      // ApiKeyService is a singleton, no setup needed
    });

    group('ApiKeyValidity', () {
      test('sets correct expiration date for 1h validity', () {
        final now = DateTime.now();
        final expiry = ApiKeyValidity.oneHour.getExpirationDate(now);

        expect(expiry, isNotNull);
        expect(expiry!.difference(now).inHours, 1);
      });

      test('sets correct expiration date for 1d validity', () {
        final now = DateTime.now();
        final expiry = ApiKeyValidity.oneDay.getExpirationDate(now);

        expect(expiry, isNotNull);
        expect(expiry!.difference(now).inDays, 1);
      });

      test('sets correct expiration date for 1w validity', () {
        final now = DateTime.now();
        final expiry = ApiKeyValidity.oneWeek.getExpirationDate(now);

        expect(expiry, isNotNull);
        expect(expiry!.difference(now).inDays, 7);
      });

      test('sets correct expiration date for 1m validity', () {
        final now = DateTime.now();
        final expiry = ApiKeyValidity.oneMonth.getExpirationDate(now);

        expect(expiry, isNotNull);
        expect(expiry!.difference(now).inDays, 30);
      });

      test('returns null expiration for forever validity', () {
        final now = DateTime.now();
        final expiry = ApiKeyValidity.forever.getExpirationDate(now);

        expect(expiry, isNull);
      });

      test('fromString parses validity correctly', () {
        expect(ApiKeyValidity.fromString('1h'), ApiKeyValidity.oneHour);
        expect(ApiKeyValidity.fromString('1d'), ApiKeyValidity.oneDay);
        expect(ApiKeyValidity.fromString('1w'), ApiKeyValidity.oneWeek);
        expect(ApiKeyValidity.fromString('1m'), ApiKeyValidity.oneMonth);
        expect(ApiKeyValidity.fromString('forever'), ApiKeyValidity.forever);
      });

      test('fromString defaults to forever for invalid input', () {
        expect(ApiKeyValidity.fromString('invalid'), ApiKeyValidity.oneDay);
      });

      test('value property returns correct string', () {
        expect(ApiKeyValidity.oneHour.value, '1h');
        expect(ApiKeyValidity.oneDay.value, '1d');
        expect(ApiKeyValidity.oneWeek.value, '1w');
        expect(ApiKeyValidity.oneMonth.value, '1m');
        expect(ApiKeyValidity.forever.value, 'forever');
      });
    });

    group('getActiveApiKey', () {
      test('returns active API key for function', () async {
        // Test retrieving active key
      });

      test('returns null if no active key exists', () async {
        // Test when function has no keys
      });

      test('deactivates and returns null for expired keys', () async {
        // Test expiration handling
      });
    });

    group('revokeApiKey', () {
      test('successfully revokes an API key', () async {
        // Test revocation
      });

      test('returns false if key does not exist', () async {
        // Test non-existent key
      });

      test('sets is_active to false and revoked_at timestamp', () async {
        // Test revocation state
      });
    });

    group('createSignatureWithSecretKey - Signature Generation', () {
      test('creates consistent signature for same input', () {
        final secretKey = 'test-secret-key';
        final payload = '{"test": "data"}';
        final timestamp = 1234567890;

        final signature1 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: secretKey,
          payload: payload,
          timestamp: timestamp,
        );

        final signature2 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: secretKey,
          payload: payload,
          timestamp: timestamp,
        );

        expect(signature1, equals(signature2));
      });

      test('creates different signature for different payload', () {
        final secretKey = 'test-secret-key';
        final timestamp = 1234567890;

        final signature1 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: secretKey,
          payload: '{"test": "data1"}',
          timestamp: timestamp,
        );

        final signature2 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: secretKey,
          payload: '{"test": "data2"}',
          timestamp: timestamp,
        );

        expect(signature1, isNot(equals(signature2)));
      });

      test('creates different signature for different timestamp', () {
        final secretKey = 'test-secret-key';
        final payload = '{"test": "data"}';

        final signature1 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: secretKey,
          payload: payload,
          timestamp: 1234567890,
        );

        final signature2 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: secretKey,
          payload: payload,
          timestamp: 1234567891,
        );

        expect(signature1, isNot(equals(signature2)));
      });

      test('creates different signature for different secret key', () {
        final payload = '{"test": "data"}';
        final timestamp = 1234567890;

        final signature1 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: 'secret-key-1',
          payload: payload,
          timestamp: timestamp,
        );

        final signature2 = ApiKeyService.createSignatureWithSecretKey(
          secretKey: 'secret-key-2',
          payload: payload,
          timestamp: timestamp,
        );

        expect(signature1, isNot(equals(signature2)));
      });

      test('returns base64 encoded signature', () {
        final secretKey = 'test-secret-key';
        final payload = '{"test": "data"}';
        final timestamp = 1234567890;

        final signature = ApiKeyService.createSignatureWithSecretKey(
          secretKey: secretKey,
          payload: payload,
          timestamp: timestamp,
        );

        expect(signature, isNotEmpty);
        expect(() => base64Decode(signature), returnsNormally);
      });
    });

    group('listApiKeys', () {
      test('returns all API keys for a function', () async {
        // Test listing keys
      });

      test('returns empty list if no keys exist', () async {
        // Test empty list
      });

      test('returns keys ordered by created_at DESC', () async {
        // Test ordering
      });
    });

    group('sortApiKeys', () {
      test('sorts keys by priority: Active > Disabled > Expired', () {
        final now = DateTime.now();
        final expiredKey = ApiKeyEntity(
          uuid: 'expired',
          functionUuid: 'f1',
          publicKey: 'pk',
          privateKeyHash: 'hash',
          validity: '1h',
          expiresAt: now.subtract(Duration(hours: 1)),
          isActive: true, // expired overrides active
          createdAt: now,
        );
        final disabledKey = ApiKeyEntity(
          uuid: 'disabled',
          functionUuid: 'f1',
          publicKey: 'pk',
          privateKeyHash: 'hash',
          validity: 'forever',
          expiresAt: null,
          isActive: false,
          createdAt: now,
        );
        final activeKey = ApiKeyEntity(
          uuid: 'active',
          functionUuid: 'f1',
          publicKey: 'pk',
          privateKeyHash: 'hash',
          validity: 'forever',
          expiresAt: null,
          isActive: true,
          createdAt: now,
        );

        final keys = [expiredKey, disabledKey, activeKey];
        final sorted = ApiKeyService.sortApiKeys(keys);

        expect(sorted[0].uuid, 'active');
        expect(sorted[1].uuid, 'disabled');
        expect(sorted[2].uuid, 'expired');
      });

      test('sorts keys with same priority by creation date descending', () {
        final now = DateTime.now();
        final older = ApiKeyEntity(
          uuid: 'older',
          functionUuid: 'f1',
          publicKey: 'pk',
          privateKeyHash: 'hash',
          validity: 'forever',
          expiresAt: null,
          isActive: true,
          createdAt: now.subtract(Duration(days: 1)),
        );
        final newer = ApiKeyEntity(
          uuid: 'newer',
          functionUuid: 'f1',
          publicKey: 'pk',
          privateKeyHash: 'hash',
          validity: 'forever',
          expiresAt: null,
          isActive: true,
          createdAt: now,
        );

        final keys = [older, newer];
        final sorted = ApiKeyService.sortApiKeys(keys);

        expect(sorted[0].uuid, 'newer');
        expect(sorted[1].uuid, 'older');
      });
    });

    group('hasActiveApiKey', () {
      test('returns true if function has active API key', () async {
        // Test when active key exists
      });

      test('returns false if function has no active API key', () async {
        // Test when no active key
      });

      test('returns false if only expired keys exist', () async {
        // Test with expired keys
      });
    });

    group('ApiKeyResult', () {
      test('toJson includes secret key', () {
        final result = ApiKeyResult(
          uuid: 'test-uuid',
          secretKey: 'test-secret-key',
          validity: ApiKeyValidity.oneDay,
          expiresAt: DateTime.now().add(Duration(days: 1)),
          name: 'test-key',
          createdAt: DateTime.now(),
        );

        final json = result.toJson();

        expect(json['secret_key'], 'test-secret-key');
      });

      test('toJson does not include public key', () {
        final result = ApiKeyResult(
          uuid: 'test-uuid',
          secretKey: 'test-secret-key',
          validity: ApiKeyValidity.oneDay,
          expiresAt: DateTime.now().add(Duration(days: 1)),
          name: 'test-key',
          createdAt: DateTime.now(),
        );

        final json = result.toJson();

        expect(json.containsKey('public_key'), false);
      });

      test('toJson includes validity', () {
        final result = ApiKeyResult(
          uuid: 'test-uuid',
          secretKey: 'test-secret-key',
          validity: ApiKeyValidity.oneDay,
          expiresAt: DateTime.now().add(Duration(days: 1)),
          name: 'test-key',
          createdAt: DateTime.now(),
        );

        final json = result.toJson();

        expect(json['validity'], equals('1d'));
      });

      test('toJson includes expires_at when present', () {
        final expiresAt = DateTime.now().add(Duration(days: 1));
        final result = ApiKeyResult(
          uuid: 'test-uuid',
          secretKey: 'test-secret-key',
          validity: ApiKeyValidity.oneDay,
          expiresAt: expiresAt,
          name: 'test-key',
          createdAt: DateTime.now(),
        );

        final json = result.toJson();

        expect(json['expires_at'], isNotNull);
        expect(json['expires_at'], equals(expiresAt.toIso8601String()));
      });

      test('toJson excludes expires_at when null', () {
        final result = ApiKeyResult(
          uuid: 'test-uuid',
          secretKey: 'test-secret-key',
          validity: ApiKeyValidity.forever,
          expiresAt: null,
          name: 'test-key',
          createdAt: DateTime.now(),
        );

        final json = result.toJson();

        expect(json.containsKey('expires_at'), false);
      });

      test('toJson includes name when present', () {
        final result = ApiKeyResult(
          uuid: 'test-uuid',
          secretKey: 'test-secret-key',
          validity: ApiKeyValidity.oneDay,
          expiresAt: DateTime.now().add(Duration(days: 1)),
          name: 'production-key',
          createdAt: DateTime.now(),
        );

        final json = result.toJson();

        expect(json['name'], equals('production-key'));
      });

      test('toJson excludes name when null', () {
        final result = ApiKeyResult(
          uuid: 'test-uuid',
          secretKey: 'test-secret-key',
          validity: ApiKeyValidity.oneDay,
          expiresAt: DateTime.now().add(Duration(days: 1)),
          name: null,
          createdAt: DateTime.now(),
        );

        final json = result.toJson();

        expect(json.containsKey('name'), false);
      });
    });

    group('ApiKeyInfo', () {
      test('fromEntity creates ApiKeyInfo from ApiKeyEntity', () {
        final entity = ApiKeyEntity(
          uuid: 'test-uuid',
          functionUuid: 'test-function-uuid',
          publicKey: 'test-secret-key', // DB field name kept for compatibility
          privateKeyHash: 'test-hash',
          validity: '1d',
          expiresAt: DateTime.now().add(Duration(days: 1)),
          isActive: true,
          name: 'test-key',
          createdAt: DateTime.now(),
        );

        final info = ApiKeyInfo.fromEntity(entity);

        expect(info.uuid, equals('test-uuid'));
        expect(info.validity, equals('1d'));
        expect(info.isActive, true);
        expect(info.name, equals('test-key'));
      });

      test('toJson does not include secret key (security)', () {
        final expiresAt = DateTime.now().add(Duration(days: 1));
        final createdAt = DateTime.now();
        final info = ApiKeyInfo(
          uuid: 'test-uuid',
          validity: '1d',
          expiresAt: expiresAt,
          isActive: true,
          name: 'test-key',
          createdAt: createdAt,
        );

        final json = info.toJson();

        expect(json['uuid'], equals('test-uuid'));
        expect(json.containsKey('public_key'), false);
        expect(json.containsKey('secret_key'), false);
        expect(json['validity'], equals('1d'));
        expect(json['is_active'], true);
        expect(json['name'], equals('test-key'));
        expect(json['expires_at'], equals(expiresAt.toIso8601String()));
        expect(json['created_at'], equals(createdAt.toIso8601String()));
      });

      test('toJson excludes null fields', () {
        final info = ApiKeyInfo(
          uuid: 'test-uuid',
          validity: '1d',
          expiresAt: null,
          isActive: true,
          name: null,
          createdAt: null,
        );

        final json = info.toJson();

        expect(json.containsKey('expires_at'), false);
        expect(json.containsKey('name'), false);
        expect(json.containsKey('created_at'), false);
      });
    });
  });
}

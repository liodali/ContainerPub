import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

final initializeAppProvider = FutureProvider.autoDispose<bool>((ref) async {
  await Hive.initFlutter();
  await ApiKeyStorage.instance.init();
  await TokenService.tokenService.init();
  return true;
});
final apiKeyStorageProvider = Provider((ref) => ApiKeyStorage.instance);

final baseURLProvider = Provider<String>(
  (ref) => 'http://127.0.0.1:8080',
);

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      baseUrl: ref.read(baseURLProvider),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  ),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import 'auth_provider.dart';

final apiClientProvider = Provider<CloudApiClient>((ref) {
  final authState = ref.watch(authProvider);
  // Using localhost:8080 for now.
  return CloudApiClient(
    baseUrl: 'http://127.0.0.1:8080',
    token: authState.token,
  );
});

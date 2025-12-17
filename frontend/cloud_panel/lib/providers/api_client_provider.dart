import 'package:cloud_panel/providers/common_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import 'auth_provider.dart';

final apiClientProvider = Provider<CloudApiClient>((ref) {
  return CloudApiClient(
    baseUrl: ref.read(baseURLProvider),
    authInterceptor: ref.watch(tokenInterceptorProvider),
  );
});

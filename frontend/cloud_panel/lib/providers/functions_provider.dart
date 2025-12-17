import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import 'api_client_provider.dart';

final functionsProvider = FutureProvider.autoDispose<List<CloudFunction>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  return client.listFunctions();
});

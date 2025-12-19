import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import 'api_client_provider.dart';

final functionDetailsProvider = FutureProvider.family
    .autoDispose<CloudFunction, String>((
      ref,
      uuid,
    ) async {
      final client = ref.watch(apiClientProvider);
      return client.getFunction(uuid);
    });

final functionDeploymentsProvider = FutureProvider.family
    .autoDispose<List<FunctionDeployment>, String>((ref, uuid) async {
      final client = ref.watch(apiClientProvider);
      return client.getDeployments(uuid);
    });

final functionApiKeysProvider = FutureProvider.family
    .autoDispose<List<ApiKey>, String>((
      ref,
      uuid,
    ) async {
      final client = ref.watch(apiClientProvider);
      return client.listApiKeys(uuid);
    });

final functionStatsProvider = FutureProvider.family
    .autoDispose<FunctionStats, String>((
      ref,
      uuid,
    ) async {
      final client = ref.watch(apiClientProvider);
      return client.getStats(uuid);
    });

final functionHourlyStatsProvider = FutureProvider.family
    .autoDispose<HourlyStatsResponse, String>((ref, uuid) async {
      final client = ref.watch(apiClientProvider);
      return client.getHourlyStats(uuid, hours: 24);
    });

final functionDailyStatsProvider = FutureProvider.family
    .autoDispose<DailyStatsResponse, String>((ref, uuid) async {
      final client = ref.watch(apiClientProvider);
      return client.getDailyStats(uuid, days: 7);
    });

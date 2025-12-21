import 'package:intl/intl.dart';

const dateWithTimeFormatterStr = 'yyyy-MM-dd HH:mm:ss';
const dateFormatterStr = 'yyyy-MM-dd';
final dateWithTimeFormater = DateFormat(dateWithTimeFormatterStr);
final dateFormatter = DateFormat(dateFormatterStr);

class CommonsApis {
  static const String apiBaseUrl = '/api';

  ///auth
  static const String apiRefreshTokenPath =
      '${CommonsApis.apiBaseUrl}/auth/refresh';
  static const String apiLoginPath = '${CommonsApis.apiBaseUrl}/auth/login';
  static const String apiRegisterPath =
      '${CommonsApis.apiBaseUrl}/auth/register';

  ///functions
  static const String apiFunctionsPath = '${CommonsApis.apiBaseUrl}/functions';
  static const String apiFunctionLitsPath = CommonsApis.apiFunctionsPath;
  static const String apiCreateFunctionPath =
      '${CommonsApis.apiFunctionsPath}/init';
  static String apiGetDeploymentsPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid/deployments';
  static String apiRollbackFunctionPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid/rollback';
  static String apiGetFunctionsPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid';
  static String apiDeleteFunctionPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid/delete';
  static String apiInvokeFunctionPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid/invoke';

  ///stats
  static String get apiGetOverviewStatsPath =>
      '${CommonsApis.apiBaseUrl}/stats/overview';
  static String apiGetFunctionStatsPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid/stats';
  static String apiGetFunctionHourlyStatsPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid/stats/hourly';
  static String apiGetFunctionDailyStatsPath(String uuid) =>
      '${CommonsApis.apiFunctionsPath}/$uuid/stats/daily';

  ///apiKey function
  static const String apiGetApiKeyPath =
      '${CommonsApis.apiBaseUrl}/functions/api_key';
}

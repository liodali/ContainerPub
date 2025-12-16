import 'package:cloud_panel/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

final initializeAppProvider = FutureProvider.autoDispose<bool>((ref) async {
  await Hive.initFlutter();
  await AuthService.authService.init();
  return true;
});

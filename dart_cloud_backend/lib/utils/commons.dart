import 'dart:convert';

import 'package:collection/collection.dart';

enum DeploymentStatus { init, building, active, disabled, deleted }

enum DeployStatus { active, disabled, archived }

enum LogLevels { info, warning, error, debug }

enum OrderSQLDirection {
  asc('ASC'),
  desc('DESC')
  ;

  const OrderSQLDirection(this.label);
  final String label;
}

extension StringExtension on String {
  String get encode => base64.encode(utf8.encode(this));
  String get decode {
    try {
      return utf8.decode(base64.decode(this));
    } catch (e) {
      return this;
    }
  }

  String get contentDisposition {
    final parts = this.split(';').map((part) => part.trim()).toList();
    return parts.first;
  }

  String retrieveFieldName() {
    final parts = this.split(';').map((part) => part.trim()).toList();
    String field = parts.firstWhere((part) => part.startsWith('name='));
    return field.split('=').last.replaceAll("\"", "");
  }

  bool isFileField() {
    final parts = this.split(';').map((part) => part.trim()).toList();
    return parts.firstWhereOrNull((part) => part.startsWith('filename=')) != null;
  }
}

const String _notSet = 'DART_DEFINE_NOT_SET';
String? getValueFromEnv(String key) {
  String value = String.fromEnvironment(key, defaultValue: _notSet);
  return value == _notSet ? null : value;
}

bool? getBoolValueFromEnv(String key, bool defaultValue) =>
    bool.fromEnvironment(key, defaultValue: defaultValue);

T? getGenericValueFromEnv<T extends Comparable>(String key, Comparable defaultValue) {
  // T value = T.fromEnvironment(key, defaultValue: _notSet);
  // return value == _notSet ? null : value;
  return switch (T.runtimeType) {
        String => String.fromEnvironment(key, defaultValue: _notSet),
        int => int.fromEnvironment(key, defaultValue: defaultValue as int),
        double => double.tryParse(String.fromEnvironment(key, defaultValue: _notSet)),
        _ => throw Exception('Unsupported type'),
      }
      as T?;
}

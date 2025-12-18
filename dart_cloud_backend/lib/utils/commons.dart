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

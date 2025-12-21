import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:cloud_panel/l10n/app_localizations.dart';

enum SortDeploy {
  versionDesc('version_desc', 'Version (Desc)'),
  versionAsc('version_asc', 'Version (Asc)'),
  dateDesc('date_desc', 'Date (Newest)'),
  dateAsc('date_asc', 'Date (Oldest)')
  ;

  const SortDeploy(this.value, this.text);
  final String value;
  final String text;

  List<String> get sortValues => values.map((e) => e.value).toList();

  static SortDeploy fromValue(String name) {
    return values.firstWhere((e) => e.value == name);
  }

  String localized(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SortDeploy.versionDesc:
        return l10n.versionDesc;
      case SortDeploy.versionAsc:
        return l10n.versionAsc;
      case SortDeploy.dateDesc:
        return l10n.dateNewest;
      case SortDeploy.dateAsc:
        return l10n.dateOldest;
    }
  }
}

enum ApiKeyValidity {
  oneHour('1h', '1 Hour'),
  oneDay('1d', '1 Day'),
  oneWeek('1w', '1 Week'),
  oneMonth('1m', '1 Month'),
  forever('forever', 'Forever')
  ;

  const ApiKeyValidity(this.value, this.label);
  final String value;
  final String label;

  static ApiKeyValidity fromValue(String val) {
    return values.firstWhere((e) => e.value == val);
  }

  String localized(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ApiKeyValidity.oneHour:
        return l10n.oneHour;
      case ApiKeyValidity.oneDay:
        return l10n.oneDay;
      case ApiKeyValidity.oneWeek:
        return l10n.oneWeek;
      case ApiKeyValidity.oneMonth:
        return l10n.oneMonth;
      case ApiKeyValidity.forever:
        return l10n.forever;
    }
  }
}

enum FunctionStatus {
  init(Colors.grey),
  building(Colors.orange),
  active(Colors.green),
  inactive(Colors.red)
  ;

  const FunctionStatus(this.color);
  final Color color;

  static FunctionStatus fromString(String status) {
    return FunctionStatus.values.firstWhere(
      (element) => element.name == status,
      orElse: () => FunctionStatus.init,
    );
  }

  Widget toWidget() {
    return Container(
      padding: const .symmetric(horizontal: 8),
      margin: const .only(left: 8, top: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

extension FunctionStatusExtension on CloudFunction {
  Widget get statusWidget => FunctionStatus.fromString(status).toWidget();
}

extension DateFormatExtension on DateTime {
  String get formattedDate => dateFormatter.format(this);
}

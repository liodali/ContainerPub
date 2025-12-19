import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:flutter/widgets.dart'
    show Color, Widget, Container, BoxDecoration, BoxShape;
import 'package:flutter/material.dart' show Colors;

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
import 'package:flutter/widgets.dart';

class DeviceModel {
  String? name;
  Color? color;
  bool isActive = false;
  String? icon;

  DeviceModel({
    required this.name,
    required this.color,
    required this.isActive,
    required this.icon,
  });
}

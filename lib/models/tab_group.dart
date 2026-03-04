import 'package:flutter/material.dart';

class TabGroup {
  final String id;
  String name;
  Color color;
  bool isCollapsed;

  TabGroup({
    required this.id,
    required this.name,
    this.color = Colors.blueAccent,
    this.isCollapsed = false,
  });
}

import 'package:flutter/material.dart';

Color parseHexColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) {
    return const Color(0xFF3B82F6); // default blue
  }
  String formatted = hexString.replaceAll('#', '');
  if (formatted.length == 6) {
    formatted = 'FF$formatted';
  }
  return Color(int.parse(formatted, radix: 16));
}

String toHexColor(int colorValue) {
  final hex = Color(colorValue).value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  return '#$hex';
}

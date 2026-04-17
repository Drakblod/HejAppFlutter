import 'package:flutter/material.dart';

class AppThemes {
  static const Map<String, List<Color>> gradients = {
    'green_mist': [Color(0xFF2E7D32), Color(0xFF81C784)],
    'ocean_breeze': [Color(0xFF0277BD), Color(0xFF4FC3F7)],
    'sunset_glow': [Color(0xFFD84315), Color(0xFFFFB74D)],
  };

  static List<Color>? getGradient(String themeId) {
    return gradients[themeId];
  }

  static const List<Map<String, dynamic>> presets = [
    {'id': 'default', 'name': 'Default (Grey)', 'colors': [Colors.grey, Colors.blueGrey]},
    {'id': 'green_mist', 'name': 'Green Mist', 'colors': [Color(0xFF2E7D32), Color(0xFF81C784)]},
    {'id': 'ocean_breeze', 'name': 'Ocean Breeze', 'colors': [Color(0xFF0277BD), Color(0xFF4FC3F7)]},
    {'id': 'sunset_glow', 'name': 'Sunset Glow', 'colors': [Color(0xFFD84315), Color(0xFFFFB74D)]},
  ];
}

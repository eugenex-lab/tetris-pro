import 'package:flutter/material.dart';

class AppConstants {
  static const int gridRows = 20;
  static const int gridColumns = 10;

  static const Map<String, List<List<int>>> tetrominos = {
    'I': [
      [1, 1, 1, 1],
    ],
    'J': [
      [1, 0, 0],
      [1, 1, 1],
    ],
    'L': [
      [0, 0, 1],
      [1, 1, 1],
    ],
    'O': [
      [1, 1],
      [1, 1],
    ],
    'S': [
      [0, 1, 1],
      [1, 1, 0],
    ],
    'T': [
      [0, 1, 0],
      [1, 1, 1],
    ],
    'Z': [
      [1, 1, 0],
      [0, 1, 1],
    ],
  };

  static const Map<String, Color> kBlockColors = {
    'I': Color(0xFF00BCD4), // Cyan
    'J': Color(0xFF3F51B5), // Indigo
    'L': Color(0xFFFF9800), // Orange
    'O': Color(0xFFFFEB3B), // Yellow
    'S': Color(0xFF4CAF50), // Green
    'T': Color(0xFF9C27B0), // Purple
    'Z': Color(0xFFF44336), // Red
  };
}

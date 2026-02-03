import 'package:flutter/material.dart';

class AppConstants {
  static const int gridRows = 20;
  static const int gridColumns = 10;
  
  static const Map<String, List<List<int>>> tetrominos = {
    'I': [
      [1, 1, 1, 1]
    ],
    'J': [
      [1, 0, 0],
      [1, 1, 1]
    ],
    'L': [
      [0, 0, 1],
      [1, 1, 1]
    ],
    'O': [
      [1, 1],
      [1, 1]
    ],
    'S': [
      [0, 1, 1],
      [1, 1, 0]
    ],
    'T': [
      [0, 1, 0],
      [1, 1, 1]
    ],
    'Z': [
      [1, 1, 0],
      [0, 1, 1]
    ],
  };

  static const Map<String, Color> kBlockColors = {
    'I': Color(0xFF8D6E63), // Wood tint for I
    'J': Color(0xFFA1887F), // Wood tint for J
    'L': Color(0xFFBCAAA4), // Wood tint for L
    'O': Color(0xFFD7CCC8), // Wood tint for O
    'S': Color(0xFF795548), // Wood tint for S
    'T': Color(0xFF6D4C41), // Wood tint for T
    'Z': Color(0xFF5D4037), // Wood tint for Z
  };
}

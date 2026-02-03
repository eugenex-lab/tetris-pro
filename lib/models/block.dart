import 'package:flutter/material.dart';

class Block {
  List<List<int>> shape;
  Color color;
  int x;
  int y;
  String type;

  Block({
    required this.shape,
    required this.color,
    required this.type,
    this.x = 0,
    this.y = 0,
  });

  void rotate() {
    // Transpose and reverse rows for clockwise rotation
    if (type == 'O') return; // O doesn't rotate
    
    int rows = shape.length;
    int cols = shape[0].length;
    
    List<List<int>> newShape = List.generate(cols, (i) => List.filled(rows, 0));
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            newShape[j][rows - 1 - i] = shape[i][j];
        }
    }
    shape = newShape;
  }
}

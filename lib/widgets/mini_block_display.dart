import 'package:flutter/material.dart';
import '../models/block.dart';
import '../core/app_theme.dart';

class MiniBlockDisplay extends StatelessWidget {
  final Block? block;
  final String label;

  const MiniBlockDisplay({super.key, required this.block, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.surface),
          ),
          child: Center(
            child: block == null
                ? Container()
                : SizedBox(
                   width: block!.shape[0].length * 10.0,
                   height: block!.shape.length * 10.0,
                   child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: block!.shape.length * block!.shape[0].length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: block!.shape[0].length,
                    ),
                    itemBuilder: (context, index) {
                      int r = index ~/ block!.shape[0].length;
                      int c = index % block!.shape[0].length;
                      if (block!.shape[r][c] == 1) {
                         return Container(
                             margin: const EdgeInsets.all(1),
                             color: block!.color,
                         );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

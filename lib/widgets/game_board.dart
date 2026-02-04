import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/core/constants.dart';
import 'package:tetris_pro/providers/game_provider.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppConstants.gridColumns / AppConstants.gridRows,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26, // Slightly clearer background to see grid
          border: Border.all(color: AppTheme.woodLight, width: 4),
          borderRadius: BorderRadius.circular(8),
          image: const DecorationImage(
            image: NetworkImage(
              "https://www.transparenttextures.com/patterns/wood-pattern.png",
            ), // Placeholder texture
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Consumer<GameProvider>(
          builder: (context, game, child) {
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppConstants.gridRows * AppConstants.gridColumns,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppConstants.gridColumns,
              ),
              itemBuilder: (context, index) {
                int r = index ~/ AppConstants.gridColumns;
                int c = index % AppConstants.gridColumns;

                Color? color = game.grid[r][c];
                // Overlay current block
                if (game.currentBlock != null) {
                  int bx = c - game.currentBlock!.x;
                  int by = r - game.currentBlock!.y;

                  if (by >= 0 &&
                      by < game.currentBlock!.shape.length &&
                      bx >= 0 &&
                      bx < game.currentBlock!.shape[by].length &&
                      game.currentBlock!.shape[by][bx] == 1) {
                    color = game.currentBlock!.color;
                  }
                }

                // Check ghost block (only if no solid block there)
                bool isGhost = false;
                if (color == null && game.ghostBlock != null) {
                  int bx = c - game.ghostBlock!.x;
                  int by = r - game.ghostBlock!.y;

                  if (by >= 0 &&
                      by < game.ghostBlock!.shape.length &&
                      bx >= 0 &&
                      bx < game.ghostBlock!.shape[by].length &&
                      game.ghostBlock!.shape[by][bx] == 1) {
                    color = game.ghostBlock!.color.withValues(alpha: 0.3);
                    isGhost = true;
                  }
                }

                if (color == null) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 0.5,
                      ),
                    ),
                  );
                }

                // Render Ghost Block (faint outline)
                if (isGhost) {
                  return Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      color: color.withValues(alpha: 0.1), // Slight fill
                    ),
                  );
                }

                // Render Solid Block
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          Colors.white.withValues(alpha: 0.2),
                          color,
                        ),
                        color,
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

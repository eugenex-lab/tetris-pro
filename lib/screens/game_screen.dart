import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/widgets/game_board.dart';
import 'package:tetris_pro/widgets/mini_block_display.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Start game after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHUD(game),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            MiniBlockDisplay(
                              block: game.holdBlock,
                              label: "HOLD",
                            ),
                            const SizedBox(height: 20),
                            // Add life indicators
                            Column(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                Text(
                                  "${game.lives}",
                                  style: AppTheme.bodyStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: GameBoard()),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            MiniBlockDisplay(
                              block: game.nextBlock,
                              label: "NEXT",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _buildControls(context, game),
                const SizedBox(height: 10),
                // Ad Banner Placeholder
                Container(
                  height: 50,
                  color: Colors.black26,
                  child: Center(
                    child: Text(
                      "AdMob Banner",
                      style: TextStyle(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (game.isPaused)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("PAUSED", style: AppTheme.titleStyle),
                    ElevatedButton(
                      onPressed: () => game.pauseGame(),
                      child: const Text("RESUME"),
                    ),
                  ],
                ),
              ),
            ),

          if (game.isGameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.woodLight, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "GAME OVER",
                        style: AppTheme.titleStyle.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Score: ${game.score}",
                        style: AppTheme.bodyStyle.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      if (game.lives <
                          3) // Assuming logic allows revive if we have logic for it, but basically Game Over means lost.
                        // Actually user asked for Revive Mechanic.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.video_library),
                              label: const Text("Revive"),
                              onPressed: () {
                                game.revive(); // Basic revive
                              },
                            ),
                            ElevatedButton(
                              onPressed: () {
                                game.restartGame();
                              },
                              child: const Text("Restart"),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Exit to Menu"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHUD(GameProvider game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.woodDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LEVEL",
                style: TextStyle(
                  color: AppTheme.primary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              Text(
                "${game.level}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                "SCORE",
                style: TextStyle(
                  color: AppTheme.primary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              Text(
                "${game.score}",
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "COINS",
                style: TextStyle(
                  color: AppTheme.primary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.coins,
                    size: 12,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${game.coins}",
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              game.isPaused ? Icons.play_arrow : Icons.pause,
              color: AppTheme.primary,
            ),
            onPressed: () => game.pauseGame(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, GameProvider game) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // Row 1: Rotation, etc.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ctrlBtn(
                icon: FontAwesomeIcons.rotate,
                onTap: game.rotateBlock,
                size: 60,
              ),
              _ctrlBtn(
                icon: FontAwesomeIcons.arrowDown,
                onTap: game.dropBlock,
                size: 60,
                color: Colors.amber[900],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Movement
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ctrlBtn(
                icon: FontAwesomeIcons.arrowLeft,
                onTap: game.moveLeft,
                size: 70,
              ),
              _ctrlBtn(
                icon: FontAwesomeIcons.chevronDown,
                onTap: game.moveDown,
                size: 70,
              ),
              _ctrlBtn(
                icon: FontAwesomeIcons.arrowRight,
                onTap: game.moveRight,
                size: 70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required VoidCallback onTap,
    double size = 50,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? AppTheme.woodLight,
          shape: BoxShape.circle,
          boxShadow: [
            const BoxShadow(
              color: Colors.black45,
              offset: Offset(2, 3),
              blurRadius: 4,
            ),
            BoxShadow(
              color: (color ?? AppTheme.woodLight).withValues(alpha: 0.5),
              offset: const Offset(-1, -1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.woodDark, size: size * 0.5),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/providers/audio_provider.dart';
import 'package:tetris_pro/services/ad_manager.dart';
import 'package:tetris_pro/widgets/game_board.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
                  child: GestureDetector(
                    onTap: () => game.rotateBlock(),
                    onHorizontalDragUpdate: (details) {
                      // Sensitivity threshold
                      if (details.delta.dx > 15) {
                        game.moveRight();
                      } else if (details.delta.dx < -15) {
                        game.moveLeft();
                      }
                    },
                    onVerticalDragUpdate: (details) {
                      if (details.delta.dy > 10) {
                        game.moveDown();
                      }
                    },
                    onVerticalDragEnd: (details) {
                      // Hard drop on fast swipe down
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 1000) {
                        game.dropBlock();
                      }
                    },
                    child: Container(
                      color: Colors.transparent, // Capture taps
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width * 2,
                            child: GameBoard(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Banner Ad
                AdManager.instance.getBannerWidget() ??
                    Container(
                      height: 50,
                      color: Colors.black12,
                      child: const Center(
                        child: Text(
                          "Ad Loading...",
                          style: TextStyle(color: Colors.white24),
                        ),
                      ),
                    ),
              ],
            ),
          ),

          // Dialogs
          if (game.showContinueDialog && !game.isGameOver)
            _buildContinueDialog(context, game),
          if (game.isPaused && !game.showContinueDialog && !game.isGameOver)
            _buildPauseOverlay(context, game),
          if (game.isGameOver) _buildGameOverOverlay(context, game),
        ],
      ),
    );
  }

  Widget _buildHUD(GameProvider game) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D2620), // Dark warm wood
            const Color(0xFF140D09), // Almost black
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Score
          Expanded(
            child: _buildHUDStat(
              "SCORE",
              "${game.score}",
              CrossAxisAlignment.start,
            ),
          ),

          // Center: NEXT PIECE (Hero Element)
          _buildNextDisplay(game.nextBlock),

          // Right: Coins & Pause
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHUDStat(
                  "COINS",
                  "${game.coins}",
                  CrossAxisAlignment.end,
                  icon: FontAwesomeIcons.coins,
                ),
                const SizedBox(width: 12),
                _buildPauseBtn(game),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextDisplay(dynamic block) {
    return Container(
      width: 120,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFB74D), // Gold border
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.25),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3E2723), // Dark wood
            const Color(0xFF151515), // Black
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: const Text(
              "NEXT",
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 40,
                width: 60,
                child: block == null
                    ? const Center(
                        child: Text(
                          "...",
                          style: TextStyle(color: Colors.white24),
                        ),
                      )
                    : _renderMiniBlock(block),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildPauseBtn(GameProvider game) {
    return GestureDetector(
      onTap: () => game.pauseGame(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF3E2723).withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          game.isPaused ? Icons.play_arrow : Icons.pause,
          color: const Color(0xFFFFD54F),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHUDStat(
    String label,
    String value,
    CrossAxisAlignment align, {
    IconData? icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 10,
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.accent, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _renderMiniBlock(dynamic block) {
    final List<List<int>> shape = block.shape;
    final Color color = block.color;
    final int rows = shape.length;
    final int cols = shape[0].length;

    return AspectRatio(
      aspectRatio: cols / rows,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 1,
        ),
        itemCount: rows * cols,
        itemBuilder: (context, index) {
          int r = index ~/ cols;
          int c = index % cols;

          if (shape[r][c] == 1) {
            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.3),
                      color,
                    ),
                    color,
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context, GameProvider game) {
    return Container(
      color: Colors.black54,
      child: Center(
        child:
            _MenuCard(
                  title: "PAUSED",
                  children: [
                    const SizedBox(height: 20),
                    _LargeMenuButton(
                      label: "RESUME",
                      icon: FontAwesomeIcons.play,
                      onPressed: () => game.pauseGame(),
                      color: AppTheme.woodLight,
                    ),
                    const SizedBox(height: 12),
                    Consumer<AudioProvider>(
                      builder: (context, audio, _) {
                        return _LargeMenuButton(
                          label: audio.isMuted ? "SOUND: OFF" : "SOUND: ON",
                          icon: audio.isMuted
                              ? FontAwesomeIcons.volumeXmark
                              : FontAwesomeIcons.volumeHigh,
                          onPressed: () => audio.toggleMute(),
                          color: audio.isMuted
                              ? Colors.grey.withValues(alpha: 0.7)
                              : Colors.green.withValues(alpha: 0.8),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SmallMenuButton(
                          label: "RESTART",
                          icon: FontAwesomeIcons.rotateLeft,
                          onPressed: () {
                            AdManager.instance.showInterstitialAd(
                              onAdClosed: () => game.restartGame(),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _SmallMenuButton(
                          label: "MENU",
                          icon: FontAwesomeIcons.house,
                          onPressed: () {
                            AdManager.instance.showInterstitialAd(
                              onAdClosed: () => Navigator.pop(context),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                )
                .animate()
                .scale(
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.8, 0.8),
                )
                .fadeIn(duration: 200.ms),
      ),
    );
  }

  Widget _buildContinueDialog(BuildContext context, GameProvider game) {
    return Container(
      color: Colors.black87,
      child: Center(
        child:
            _MenuCard(
                  title: "CONTINUE?",
                  titleColor: AppTheme.accent,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < game.continuesRemaining
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: i < game.continuesRemaining
                                ? Colors.red
                                : Colors.red.withValues(alpha: 0.3),
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${game.continuesRemaining} hearts remaining",
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LargeMenuButton(
                      label: "WATCH AD",
                      icon: FontAwesomeIcons.video,
                      onPressed: () {
                        AdManager.instance.showRewardedAd(
                          onRewarded: () {
                            game.continueGame();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "CONTINUE!",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                duration: Duration(seconds: 1),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        );
                      },
                      color: Colors.green.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => game.finalGameOver(),
                      child: Text(
                        "GIVE UP",
                        style: AppTheme.bodyStyle.copyWith(
                          color: Colors.red.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                )
                .animate()
                .scale(
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.8, 0.8),
                )
                .fadeIn(duration: 200.ms),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, GameProvider game) {
    return Container(
      color: Colors.black87,
      child: Center(
        child:
            _MenuCard(
                  title: "GAME OVER",
                  titleColor: Colors.redAccent,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Score: ${game.score}",
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (game.coins >= 50)
                          _LargeMenuButton(
                            label: "REVIVE (50)",
                            icon: FontAwesomeIcons.heartPulse,
                            onPressed: () => game.revive(),
                            color: Colors.redAccent.withValues(alpha: 0.8),
                          )
                        else
                          Column(
                            children: [
                              _LargeMenuButton(
                                label: "WATCH AD",
                                icon: FontAwesomeIcons.video,
                                onPressed: () {
                                  AdManager.instance.showRewardedAd(
                                    onRewarded: () => game.revive(),
                                  );
                                },
                                color: Colors.green.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 12),
                              _LargeMenuButton(
                                label: "RESTART",
                                icon: FontAwesomeIcons.rotateLeft,
                                onPressed: () {
                                  AdManager.instance.showInterstitialAd(
                                    onAdClosed: () => game.restartGame(),
                                  );
                                },
                                color: AppTheme.woodLight,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        AdManager.instance.showInterstitialAd(
                          onAdClosed: () => Navigator.pop(context),
                        );
                      },
                      child: Text(
                        "EXIT TO MENU",
                        style: AppTheme.bodyStyle.copyWith(
                          letterSpacing: 2,
                          color: AppTheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                )
                .animate()
                .scale(
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.5, 0.5),
                )
                .fadeIn(duration: 300.ms),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? titleColor;

  const _MenuCard({
    required this.title,
    required this.children,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFE7DCC9), // Textured light wood color
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC4B59D), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalStripesPainter(
                color: const Color(0xFFDED1BA).withValues(alpha: 0.5),
              ),
            ),
          ),
          // Screws details
          const Positioned(top: -10, left: -10, child: _ScrewDetail()),
          const Positioned(top: -10, right: -10, child: _ScrewDetail()),
          const Positioned(bottom: -10, left: -10, child: _ScrewDetail()),
          const Positioned(bottom: -10, right: -10, child: _ScrewDetail()),
          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.titleStyle.copyWith(
                  color: titleColor ?? const Color(0xFF3E2723),
                  fontSize: 36,
                  shadows: [
                    Shadow(
                      color: Colors.black12,
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...children,
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "...",
                    style: TextStyle(color: Colors.black26, fontSize: 24),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrewDetail extends StatelessWidget {
  const _ScrewDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
      child: const Icon(Icons.add, size: 10, color: Colors.black26),
    );
  }
}

class _LargeMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _LargeMenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5D4037),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFFB74D), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTheme.buttonStyle.copyWith(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SmallMenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF8D6E63).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 3),
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFFD54F), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  final Color color;

  _DiagonalStripesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    const double gap = 8;

    for (double i = -size.height; i < size.width; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

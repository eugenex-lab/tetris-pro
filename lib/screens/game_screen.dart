import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/providers/audio_provider.dart';
import 'package:tetris_pro/services/ad_manager.dart';
import 'package:tetris_pro/widgets/game_board.dart';
import 'package:tetris_pro/widgets/mini_block_display.dart';
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

          // Continue Dialog (shows before game over when continues remain)
          if (game.showContinueDialog && !game.isGameOver)
            _buildContinueDialog(context, game),

          // Pause Overlay (only when paused, not during continue dialog)
          if (game.isPaused && !game.showContinueDialog && !game.isGameOver)
            _buildPauseOverlay(context, game),

          // Game Over Overlay (only when truly game over, no continues left)
          if (game.isGameOver) _buildGameOverOverlay(context, game),
        ],
      ),
    );
  }

  Widget _buildHUD(GameProvider game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.woodDark.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: AppTheme.woodLight, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SCORE",
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              Text(
                "${game.score}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Level
          Column(
            children: [
              Text(
                "LEVEL",
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              Text(
                "${game.level}",
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Coins
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "COINS",
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.coins,
                    color: AppTheme.accent,
                    size: 14,
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

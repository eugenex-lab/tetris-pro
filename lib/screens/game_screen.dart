import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final FocusNode _focusNode;

  // Animation state
  String? _lineClearText;
  int? _lineClearCount;
  int? _coinsEarned;
  bool _showLineClearAnimation = false;
  bool _showLevelStartAnimation = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Start game after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameProvider>();
      final audio = context.read<AudioProvider>();

      // Wire up audio triggers
      game.onSoundTrigger = (effectStr) {
        SoundEffect? effect;
        if (effectStr == 'lineClear') {
          effect = SoundEffect.lineClear;
          if (game.hapticsEnabled) HapticFeedback.heavyImpact();
        }
        if (effectStr == 'gameOver') effect = SoundEffect.gameOver;
        if (effectStr == 'drop') {
          effect = SoundEffect.drop;
          if (game.hapticsEnabled) HapticFeedback.mediumImpact();
        }

        if (effect != null) {
          audio.playSoundEffect(effect);
        }
      };

      // Wire up animation callbacks
      game.onLineClear = (linesCleared, coinsEarned) {
        setState(() {
          _lineClearCount = linesCleared;
          _coinsEarned = coinsEarned;
          switch (linesCleared) {
            case 1:
              _lineClearText = "NICE!";
              break;
            case 2:
              _lineClearText = "DOUBLE!";
              break;
            case 3:
              _lineClearText = "TRIPLE!!!";
              break;
            case 4:
              _lineClearText = "TETRIS!!!!";
              break;
          }
          _showLineClearAnimation = true;
        });

        // Hide animation after delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _showLineClearAnimation = false;
            });
          }
        });
      };

      game.onLevelStart = () {
        setState(() {
          _showLevelStartAnimation = true;
        });

        // Hide animation after delay
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showLevelStartAnimation = false;
            });
          }
        });
      };

      game.startGame();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    // Ensure we keep focus for keyboard events
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.keyA) {
            game.moveLeft();
          } else if (key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.keyD) {
            game.moveRight();
          } else if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.keyW) {
            game.rotateBlock();
          } else if (key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.keyS) {
            game.moveDown();
          } else if (key == LogicalKeyboardKey.space) {
            game.dropBlock();
          } else if (key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.keyP) {
            game.pauseGame();
          } else if (key == LogicalKeyboardKey.keyL) {
            game.triggerLevelUpDebug();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHUD(game),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.read<AudioProvider>().playSoundEffect(
                          SoundEffect.rotate,
                        );
                        if (game.hapticsEnabled)
                          HapticFeedback.selectionClick();
                        game.rotateBlock();
                      },
                      onHorizontalDragUpdate: (details) {
                        // Sensitivity threshold
                        if (details.delta.dx > 15) {
                          context.read<AudioProvider>().playSoundEffect(
                            SoundEffect.rotate,
                          ); // Using rotate sound for moves if specific move sound missing
                          if (game.hapticsEnabled)
                            HapticFeedback.selectionClick();
                          game.moveRight();
                        } else if (details.delta.dx < -15) {
                          context.read<AudioProvider>().playSoundEffect(
                            SoundEffect.rotate,
                          );
                          if (game.hapticsEnabled)
                            HapticFeedback.selectionClick();
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
                          context.read<AudioProvider>().playSoundEffect(
                            SoundEffect.drop,
                          );
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
                  AdManager.instance.buildBannerWidget(AdBannerType.game),
                ],
              ),
            ),

            // Dialogs
            if (game.showContinueDialog && !game.isGameOver)
              _buildContinueDialog(context, game),
            if (game.isPaused && !game.showContinueDialog && !game.isGameOver)
              _buildPauseOverlay(context, game),
            if (game.isGameOver) _buildGameOverOverlay(context, game),
            if (game.showSuccessModal) _buildSuccessModal(context, game),

            // Line clear animation
            if (_showLineClearAnimation) _buildLineClearAnimation(),

            // Level start animation
            if (_showLevelStartAnimation) _buildLevelStartAnimation(),
          ],
        ),
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
          // Left: Score & Best
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHUDStat(
                  "SCORE",
                  "${game.score}",
                  CrossAxisAlignment.start,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHUDStat(
                      "LEVEL",
                      "${game.level}",
                      CrossAxisAlignment.start,
                      fontSize: 14,
                      labelSize: 8,
                    ),
                    const SizedBox(width: 15),
                    _buildHUDStat(
                      "TARGET",
                      "${game.linesUntilNextLevel}",
                      CrossAxisAlignment.start,
                      fontSize: 14,
                      labelSize: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center: NEXT PIECE (Hero Element)
          _buildNextDisplay(game.nextBlock),

          // Right: Coins & Pause
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHUDStat(
                  "BEST",
                  "${game.highScore}",
                  CrossAxisAlignment.end,
                  fontSize: 14,
                  labelSize: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildHUDStat(
                      "COINS",
                      "${game.coins}",
                      CrossAxisAlignment.end,
                      icon: FontAwesomeIcons.coins,
                      fontSize: 14,
                      labelSize: 8,
                    ),
                    const SizedBox(width: 12),
                    _buildPauseBtn(game),
                  ],
                ),
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
      onTap: () {
        context.read<AudioProvider>().playSoundEffect(SoundEffect.buttonClick);
        game.pauseGame();
      },
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
    double fontSize = 18,
    double labelSize = 10,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: labelSize,
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
              style: TextStyle(
                color: const Color(0xFFFFD54F),
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: const [
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

    const double cellSize = 12.0;
    const double margin = 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(rows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cols, (c) {
            if (shape[r][c] == 1) {
              return Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(margin),
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
            return const SizedBox(
              width: cellSize + (margin * 2),
              height: cellSize + (margin * 2),
            );
          }),
        );
      }),
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
                      onPressed: () {
                        context.read<AudioProvider>().playSoundEffect(
                          SoundEffect.buttonClick,
                        );
                        AdManager.instance.showInterstitialAd(
                          onAdClosed: () => game.pauseGame(),
                        );
                      },
                      color: AppTheme.woodLight,
                    ),
                    const SizedBox(height: 12),
                    Consumer<AudioProvider>(
                      builder: (context, audio, _) {
                        return Column(
                          children: [
                            _LargeMenuButton(
                              label: audio.isMusicMuted
                                  ? "MUSIC: OFF"
                                  : "MUSIC: ON",
                              icon: FontAwesomeIcons.music,
                              onPressed: () {
                                audio.playSoundEffect(SoundEffect.buttonClick);
                                audio.toggleMusic();
                              },
                              color: audio.isMusicMuted
                                  ? Colors.grey.withValues(alpha: 0.7)
                                  : Colors.deepPurple.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 12),
                            _LargeMenuButton(
                              label: audio.isSfxMuted ? "SFX: OFF" : "SFX: ON",
                              icon: audio.isSfxMuted
                                  ? FontAwesomeIcons.volumeXmark
                                  : FontAwesomeIcons.volumeHigh,
                              onPressed: () {
                                audio.playSoundEffect(SoundEffect.buttonClick);
                                audio.toggleSfx();
                              },
                              color: audio.isSfxMuted
                                  ? Colors.grey.withValues(alpha: 0.7)
                                  : Colors.teal.withValues(alpha: 0.8),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LargeMenuButton(
                            label: "RESTART",
                            icon: FontAwesomeIcons.rotateLeft,
                            fontSize: 14,
                            onPressed: () {
                              context.read<AudioProvider>().playSoundEffect(
                                SoundEffect.buttonClick,
                              );
                              AdManager.instance.showInterstitialAd(
                                onAdClosed: () => game.restartGame(),
                              );
                            },
                            color: const Color(0xFF8D6E63),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LargeMenuButton(
                            label: "MENU",
                            icon: FontAwesomeIcons.house,
                            fontSize: 14,
                            onPressed: () {
                              context.read<AudioProvider>().playSoundEffect(
                                SoundEffect.buttonClick,
                              );
                              AdManager.instance.showInterstitialAd(
                                onAdClosed: () => Navigator.pop(context),
                              );
                            },
                            color: const Color(0xFF795548),
                          ),
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
                        context.read<AudioProvider>().playSoundEffect(
                          SoundEffect.buttonClick,
                        );
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
                      onPressed: () {
                        context.read<AudioProvider>().playSoundEffect(
                          SoundEffect.buttonClick,
                        );
                        game.finalGameOver();
                      },
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
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: _MenuCard(
          title: "GAME OVER",
          titleColor: Colors.redAccent,
          children: [
            const SizedBox(height: 10),
            // Stat Grid - Score and Level on one line
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGameOverStat(
                    "SCORE",
                    "${game.score}",
                    false,
                    isHighlight: game.isNewHighScore,
                    isNewBest: game.isNewHighScore,
                  ).animate().fadeIn(delay: 200.ms),
                  Container(width: 1, height: 30, color: Colors.black12),
                  _buildGameOverStat(
                    "LEVEL REACHED",
                    "${game.level}",
                    false,
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Watch Ad for Coins Banner
            _buildCoinAdBanner(context, game).animate().fadeIn(delay: 900.ms),

            // Action Buttons - Stacked and Full-Width to match other sections
            Column(
              children: [
                _LargeMenuButton(
                  label: "RESTART",
                  icon: FontAwesomeIcons.rotateLeft,
                  onPressed: () {
                    context.read<AudioProvider>().playSoundEffect(
                      SoundEffect.buttonClick,
                    );
                    AdManager.instance.showInterstitialAd(
                      onAdClosed: () => game.restartGame(),
                    );
                  },
                  color: AppTheme.woodLight,
                ),
                const SizedBox(height: 12),
                _LargeMenuButton(
                  label: "HOME",
                  icon: FontAwesomeIcons.house,
                  onPressed: () {
                    context.read<AudioProvider>().playSoundEffect(
                      SoundEffect.buttonClick,
                    );
                    AdManager.instance.showInterstitialAd(
                      onAdClosed: () => Navigator.pop(context),
                    );
                  },
                  color: const Color(0xFF8D6E63),
                ),
              ],
            ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1),
          ],
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildGameOverStat(
    String label,
    String value,
    bool primary, {
    bool isHighlight = false,
    bool isNewBest = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isNewBest)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "NEW BEST!",
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),

        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: primary ? 12 : 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: isHighlight
                ? const Color(0xFFD84315)
                : const Color(0xFF5D4037).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
              value,
              style: AppTheme.titleStyle.copyWith(
                fontSize: primary ? 48 : 36,
                color: isHighlight
                    ? const Color(0xFFD84315)
                    : const Color(0xFF3E2723),
                height: 1.1,
              ),
            )
            .animate(target: isNewBest ? 1 : 0)
            .shimmer(duration: 2.seconds, color: Colors.white54),
      ],
    );
  }

  Widget _buildCoinAdBanner(BuildContext context, GameProvider game) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdManager.instance.isOffline,
      builder: (context, isOffline, child) {
        if (isOffline) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF3E2723).withValues(alpha: 0.2),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white24,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "OFFLINE MODE 🪵",
                        style: AppTheme.titleStyle.copyWith(
                          fontSize: 14,
                          color: Colors.white38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Connect to reveal rewards",
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF8F00)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6F00).withValues(alpha: 0.5),
                offset: const Offset(0, 8),
                blurRadius: 20,
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4),
                offset: const Offset(0, 2),
                blurRadius: 0,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<AudioProvider>().playSoundEffect(
                  SoundEffect.buttonClick,
                );
                AdManager.instance.showRewardedAd(
                  onRewarded: () => game.addRewardCoins(50),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            FontAwesomeIcons.coins,
                            color: Color(0xFFFF8F00),
                            size: 24,
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          curve: Curves.easeInOut,
                        )
                        .shimmer(
                          delay: 2000.ms,
                          duration: 1000.ms,
                          color: Colors.white,
                        ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "BONUS REWARD!",
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF3E2723),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "+50 COINS",
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD84315),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E2723),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            "WATCH AD",
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          delay: 3000.ms,
                          duration: 1500.ms,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessModal(BuildContext context, GameProvider game) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: _MenuCard(
          title: "LEVEL UP!",
          titleColor: const Color(0xFF3E2723), // Brown matching PAUSED title
          children: [
            const SizedBox(height: 10),
            // Improved Trophy Visuals
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow Rings
                ...List.generate(3, (i) {
                  return Container(
                        width: 120 + (i * 20),
                        height: 120 + (i * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFFFD54F,
                            ).withValues(alpha: 0.1 - (i * 0.03)),
                            width: 2,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: (2000 + (i * 500)).ms,
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        curve: Curves.easeInOut,
                      )
                      .fadeOut();
                }),
                // Main Trophy Container
                Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E2723).withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD54F,
                            ).withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        FontAwesomeIcons.trophy,
                        color: Color(0xFFFFD54F),
                        size: 70,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .animate()
                    .shimmer(duration: 2.seconds, color: Colors.white54)
                    .shake(hz: 2, curve: Curves.easeInOut, rotation: 0.05),
              ],
            ),

            if (game.isNewHighScore) ...[
              const SizedBox(height: 8),
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      "NEW HIGH SCORE!",
                      style: TextStyle(
                        color: Color(0xFF3E2723),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1.5.seconds)
                  .scale(
                    duration: 400.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    curve: Curves.easeInOut,
                  ),
            ],

            const SizedBox(height: 32),

            // Stats Grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        "SCORE",
                        game.score.toString(),
                        FontAwesomeIcons.star,
                        const Color(0xFF5D4037),
                      ),
                      _buildStatItem(
                        "BEST",
                        game.highScore.toString(),
                        FontAwesomeIcons.trophy,
                        const Color(0xFFFFA000),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        "EARNED",
                        "+${game.levelCoins}",
                        FontAwesomeIcons.coins,
                        const Color(0xFF4CAF50),
                      ),
                      _buildStatItem(
                        "TOTAL",
                        game.coins.toString(),
                        FontAwesomeIcons.sackDollar,
                        const Color(0xFFFFD54F),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).scale(delay: 500.ms),

            const SizedBox(height: 48),

            // progression focused button
            GestureDetector(
                  onTap: () {
                    context.read<AudioProvider>().playSoundEffect(
                      SoundEffect.buttonClick,
                    );
                    AdManager.instance.showRewardedAd(
                      onRewarded: () {
                        game.acknowledgeLevelUp();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "LEVEL ${game.level} START!",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3E2723),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFFFFD54F),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF5D4037,
                      ), // matching Pause menu button brown
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 8),
                          blurRadius: 15,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.circleRight,
                          color: Color(0xFFFFD54F),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "PROCEED TO LEVEL ${game.level}",
                          style: AppTheme.buttonStyle.copyWith(
                            color: const Color(0xFFFFD54F),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  delay: 3.seconds,
                  duration: 1.5.seconds,
                  color: Colors.white24,
                )
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.5),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.video,
                  color: Colors.black26,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  "WATCH AD TO CONTINUE",
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.3),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 1.seconds),
          ],
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.titleStyle.copyWith(
            fontSize: 20,
            color: const Color(0xFF3E2723),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLineClearAnimation() {
    Color textColor;
    double fontSize;

    switch (_lineClearCount) {
      case 1:
        textColor = Colors.white;
        fontSize = 32;
        break;
      case 2:
        textColor = const Color(0xFFFFD54F);
        fontSize = 40;
        break;
      case 3:
        textColor = const Color(0xFFFF6F00);
        fontSize = 50;
        break;
      case 4:
        textColor = const Color(0xFFFF1744);
        fontSize = 60;
        break;
      default:
        textColor = Colors.white;
        fontSize = 32;
    }

    return IgnorePointer(
      child: Center(
        child:
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: textColor.withValues(alpha: 0.5),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: textColor.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _lineClearText ?? "",
                        style: AppTheme.titleStyle.copyWith(
                          fontSize: fontSize,
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: textColor.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            FontAwesomeIcons.coins,
                            color: Color(0xFFFFD54F),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "+${_coinsEarned ?? 0}",
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 20,
                              color: const Color(0xFFFFD54F),
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          if (_lineClearCount! >= 3) ...[
                            const SizedBox(width: 8),
                            const Text("🔥", style: TextStyle(fontSize: 24)),
                          ],
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 200.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 300.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shimmer(
                  duration: 800.ms,
                  color: Colors.white.withValues(alpha: 0.5),
                )
                .shake(hz: 4, rotation: _lineClearCount! >= 3 ? 0.1 : 0.03)
                .then(delay: 300.ms)
                .fadeOut(duration: 300.ms)
                .slideY(end: -0.5, curve: Curves.easeIn),
      ),
    );
  }

  Widget _buildLevelStartAnimation() {
    return IgnorePointer(
      child:
          Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                            FontAwesomeIcons.star,
                            size: 80,
                            color: const Color(0xFFFFD54F),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .rotate(duration: 2.seconds)
                          .shimmer(
                            duration: 1.seconds,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),

                      const SizedBox(height: 24),

                      Text(
                            "LEVEL START!",
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 48,
                              color: const Color(0xFFFFD54F),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .scale(duration: 500.ms, curve: Curves.elasticOut)
                          .then()
                          .shimmer(duration: 1.seconds, color: Colors.white54),

                      const SizedBox(height: 16),

                      Text(
                            "CLEAR THE BOARD!",
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 300.ms)
                          .slideY(begin: 0.5),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .then(delay: 1200.ms)
              .fadeOut(duration: 400.ms),
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
      width: 320,
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
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTheme.titleStyle.copyWith(
                    color: titleColor ?? const Color(0xFF3E2723),
                    fontSize: 32, // Slightly reduced
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ...children,
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "...",
                      style: TextStyle(color: Colors.black26, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
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
  final double fontSize;

  const _LargeMenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity, // Changed to fill available space
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
                fontSize: fontSize,
                letterSpacing: 1.2,
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

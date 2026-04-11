import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/providers/audio_provider.dart';
import 'package:tetris_pro/screens/settings_screen.dart';
import 'package:tetris_pro/services/ad_manager.dart';
import 'package:tetris_pro/widgets/game_board.dart';
import 'package:tetris_pro/widgets/tutorial_overlay.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final FocusNode _focusNode;

  // Animation state
  String? _lineClearText;
  int? _lineClearCount;
  int? _coinsEarned;
  bool _showLineClearAnimation = false;
  bool _showLevelStartAnimation = false;

  // Gesture accumulators
  double _horizontalDragDist = 0;
  double _verticalDragDist = 0;
  static const double _horizontalThreshold = 30.0;
  static const double _verticalThreshold = 25.0;

  // Hint system
  Timer? _idleTimer;
  static const int _idleTimeoutSeconds = 10;
  bool _showGestureHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

      if (game.showTutorial) {
        game.isPaused = true;
      } else {
        game.startGame();
        _resetIdleTimer();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final game = context.read<GameProvider>();
      if (!game.isPaused && !game.isGameOver) {
        game.pauseGame();
      }
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (context.read<GameProvider>().hasShownGestureHint) return;

    _idleTimer = Timer(Duration(seconds: _idleTimeoutSeconds), () {
      if (mounted &&
          !context.read<GameProvider>().isPaused &&
          !context.read<GameProvider>().isGameOver) {
        setState(() {
          _showGestureHint = true;
        });
        context.read<GameProvider>().markGestureHintShown();
      }
    });
  }

  Widget _buildGestureHint() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                          FontAwesomeIcons.chevronLeft,
                          color: Color(0xFFFFD54F),
                          size: 40,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .moveX(
                          begin: 0,
                          end: -40,
                          duration: 800.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(duration: 800.ms),
                    const SizedBox(width: 20),
                    const Icon(
                          FontAwesomeIcons.handPointer,
                          color: Colors.white,
                          size: 64,
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .moveX(
                          begin: -60,
                          end: 60,
                          duration: 1.5.seconds,
                          curve: Curves.easeInOutBack,
                        )
                        .then()
                        .moveX(
                          begin: 0,
                          end: -120,
                          duration: 1.5.seconds,
                          curve: Curves.easeInOutBack,
                        ),
                    const SizedBox(width: 20),
                    const Icon(
                          FontAwesomeIcons.chevronRight,
                          color: Color(0xFFFFD54F),
                          size: 40,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .moveX(
                          begin: 0,
                          end: 40,
                          duration: 800.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(duration: 800.ms),
                  ],
                ),
                const SizedBox(height: 48),
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "SWIPE LEFT / RIGHT",
                            textAlign: TextAlign.center,
                            style: AppTheme.titleStyle.copyWith(
                              color: const Color(0xFFFFD54F),
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "FLICK DOWN TO DROP",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .scale(duration: 500.ms, curve: Curves.easeOutBack),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
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
                        if (game.hapticsEnabled) {
                          HapticFeedback.selectionClick();
                        }
                        game.rotateBlock();
                      },
                      onHorizontalDragStart: (_) => _horizontalDragDist = 0,
                      onHorizontalDragUpdate: (details) {
                        _idleTimer?.cancel();
                        if (_showGestureHint) {
                          setState(() {
                            _showGestureHint = false;
                          });
                        }

                        _horizontalDragDist += details.delta.dx;
                        context.read<GameProvider>().markGestureHintShown();

                        // Sensitivity threshold
                        while (_horizontalDragDist > _horizontalThreshold) {
                          context.read<AudioProvider>().playSoundEffect(
                            SoundEffect.rotate,
                          ); // Using rotate sound for moves if specific move sound missing
                          if (game.hapticsEnabled) {
                            HapticFeedback.selectionClick();
                          }
                          game.moveRight();
                          _horizontalDragDist -= _horizontalThreshold;
                        }
                        while (_horizontalDragDist < -_horizontalThreshold) {
                          context.read<AudioProvider>().playSoundEffect(
                            SoundEffect.rotate,
                          );
                          if (game.hapticsEnabled) {
                            HapticFeedback.selectionClick();
                          }
                          game.moveLeft();
                          _horizontalDragDist += _horizontalThreshold;
                        }
                      },
                      onHorizontalDragEnd: (_) => _horizontalDragDist = 0,
                      onVerticalDragStart: (_) => _verticalDragDist = 0,
                      onVerticalDragUpdate: (details) {
                        _verticalDragDist += details.delta.dy;

                        if (_verticalDragDist > _verticalThreshold) {
                          game.moveDown();
                          _verticalDragDist =
                              0; // Reset for vertical to avoid "too fast" drop
                        }
                      },
                      onVerticalDragEnd: (details) {
                        _verticalDragDist = 0;
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

            // Tutorial Overlay
            if (game.showTutorial && !game.isGameOver)
              TutorialOverlay(
                onComplete: () {
                  game.completeTutorial();
                  game.startGame();
                  _resetIdleTimer();
                },
              ),

            // Gesture Hint Overlay
            if (_showGestureHint && !game.isPaused && !game.isGameOver) 
              _buildGestureHint(),

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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                  animateOnChange: true,
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
                      animateOnChange: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center: NEXT PIECE (Hero Element)
          _buildNextDisplay(game.nextBlock),

          // Right: Pause Button
          Expanded(
            child: Center(
              child: _buildPauseBtn(game),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextDisplay(dynamic block) {
    return Container(
      width: 100,
      height: 75,
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
        width: 52,
        height: 52,
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
          size: 24,
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
    bool animateOnChange = false,
  }) {
    Widget valueText = Text(
      value,
      key: ValueKey(value), // Important for flutter_animate to detect changes
      style: TextStyle(
        color: const Color(0xFFFFD54F),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
        ],
      ),
    );

    if (animateOnChange) {
      valueText = valueText
          .animate(key: ValueKey(value))
          .scale(
            duration: 200.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            duration: 200.ms,
            begin: const Offset(1.2, 1.2),
            end: const Offset(1, 1),
            curve: Curves.bounceOut,
          )
          .shimmer(duration: 400.ms, color: Colors.white24);
    }

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
            valueText,
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
                        if (AdManager.instance.canShowResumeAd(
                          pauseTime: game.pauseStartTime,
                        )) {
                          AdManager.instance.showInterstitialAd(
                            onAdClosed: () => game.pauseGame(),
                          );
                        } else {
                          game.pauseGame();
                        }
                      },
                      color: AppTheme.woodLight,
                    ),
                    const SizedBox(height: 12),
                    _LargeMenuButton(
                      label: "SETTINGS",
                      icon: FontAwesomeIcons.gear,
                      onPressed: () {
                        context.read<AudioProvider>().playSoundEffect(
                          SoundEffect.buttonClick,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      color: Colors.blueGrey.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LargeMenuButton(
                            label: "RESTART",
                            icon: FontAwesomeIcons.rotateLeft,
                            onPressed: () {
                              context.read<AudioProvider>().playSoundEffect(
                                SoundEffect.buttonClick,
                              );
                              if (AdManager.instance.canShowGameOverAd()) {
                                AdManager.instance.showInterstitialAd(
                                  onAdClosed: () => game.restartGame(),
                                );
                              } else {
                                game.restartGame();
                              }
                            },
                            color: const Color(0xFF8D6E63),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LargeMenuButton(
                            label: "HOME",
                            icon: FontAwesomeIcons.house,
                            onPressed: () {
                              context.read<AudioProvider>().playSoundEffect(
                                SoundEffect.buttonClick,
                              );
                              game.quitGame();
                              if (AdManager.instance.canShowGameOverAd()) {
                                AdManager.instance.showInterstitialAd(
                                  onAdClosed: () => Navigator.pop(context),
                                );
                              } else {
                                Navigator.pop(context);
                              }
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
                      label: "Revive (Ad)",
                      icon: FontAwesomeIcons.video,
                      onPressed: () {
                        context.read<AudioProvider>().playSoundEffect(
                          SoundEffect.buttonClick,
                        );
                        FirebaseAnalytics.instance.logEvent(
                          name: 'ad_offer_clicked',
                          parameters: {'type': 'revive', 'ad_type': 'rewarded'},
                        );
                        AdManager.instance.showRewardedAd(
                          onRewarded: () {
                            game.recordRewardedAdUse();
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
                    const SizedBox(height: 12),
                    _LargeMenuButton(
                      label: "Revive (100 Coins)",
                      icon: FontAwesomeIcons.coins,
                      onPressed: () {
                        if (game.coins < 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("NOT ENOUGH COINS!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        context.read<AudioProvider>().playSoundEffect(
                          SoundEffect.buttonClick,
                        );
                        FirebaseAnalytics.instance.logEvent(
                          name: 'ad_offer_clicked',
                          parameters: {'type': 'revive', 'ad_type': 'coins'},
                        );
                        game.revive();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "CONTINUED WITH COINS!",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            duration: Duration(seconds: 1),
                            backgroundColor: Colors.amber,
                          ),
                        );
                      },
                      color: game.coins >= 100
                          ? const Color(0xFFD84315).withValues(alpha: 0.8)
                          : Colors.grey.withValues(alpha: 0.5),
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
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: _MenuCard(
          title: "GAME OVER",
          titleColor: Colors.redAccent,
          children: [
            const SizedBox(height: 16),

            // ── Premium Score / Level Panel ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF1A1208), const Color(0xFF2D1F0A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // NEW RECORD banner
                  if (game.isNewHighScore)
                    Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD54F,
                                ).withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("🏆", style: TextStyle(fontSize: 14)),
                              SizedBox(width: 6),
                              Text(
                                "NEW RECORD!",
                                style: TextStyle(
                                  color: Color(0xFF3E2723),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text("🏆", style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1.2.seconds, color: Colors.white38)
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.05, 1.05),
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        ),

                  // Score — hero number
                  Text(
                    "SCORE",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                        "${game.score}",
                        style: TextStyle(
                          color: const Color(0xFFFFD54F),
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          shadows: [
                            Shadow(
                              color: const Color(
                                0xFFFFD54F,
                              ).withValues(alpha: 0.6),
                              blurRadius: 20,
                            ),
                            const Shadow(
                              color: Colors.black,
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      )
                      .shimmer(
                        delay: 400.ms,
                        duration: 800.ms,
                        color: Colors.white24,
                      ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFFFD54F).withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Level badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
                              ),
                              border: Border.all(
                                color: const Color(0xFFFFB74D),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFB74D,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "LVL",
                                    style: TextStyle(
                                      color: const Color(
                                        0xFFFFB74D,
                                      ).withValues(alpha: 0.7),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    "${game.level}",
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .scale(
                            begin: const Offset(0, 0),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LEVEL REACHED",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            game.level == 1
                                ? "KEEP GOING!"
                                : game.level < 5
                                ? "NICE EFFORT!"
                                : game.level < 10
                                ? "GREAT GAME!"
                                : "LEGEND! 🔥",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // Watch Ad to Continue Button
            _LargeMenuButton(
              label: "Revive (Ad)",
              icon: FontAwesomeIcons.video,
              onPressed: () {
                context.read<AudioProvider>().playSoundEffect(
                  SoundEffect.buttonClick,
                );
                AdManager.instance.showRewardedAd(
                  onRewarded: () {
                    game.recordRewardedAdUse();
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
              color: game.canWatchRewardedAd
                  ? Colors.green.withValues(alpha: 0.8)
                  : Colors.grey.withValues(alpha: 0.5),
            ).animate().fadeIn(delay: 900.ms),

            const SizedBox(height: 12),

            // Use Coins to Continue Button
            _LargeMenuButton(
              label: "Revive (100 Coins)",
              icon: FontAwesomeIcons.coins,
              onPressed: () {
                if (game.coins < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("NOT ENOUGH COINS!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                context.read<AudioProvider>().playSoundEffect(
                  SoundEffect.buttonClick,
                );
                game.revive(); // revive() consumes 100 coins and calls continueGame()
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "CONTINUED WITH COINS!",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
              color: game.coins >= 100
                  ? const Color(0xFFD84315).withValues(alpha: 0.8) // Vibrant Orange
                  : Colors.grey.withValues(alpha: 0.5),
            ).animate().fadeIn(delay: 1000.ms),

            const SizedBox(height: 12),

            // Action Buttons
            Column(
              children: [
                _LargeMenuButton(
                  label: "RESTART",
                  icon: FontAwesomeIcons.rotateLeft,
                  onPressed: () {
                    context.read<AudioProvider>().playSoundEffect(
                      SoundEffect.buttonClick,
                    );
                    if (AdManager.instance.canShowGameOverAd()) {
                      AdManager.instance.showInterstitialAd(
                        onAdClosed: () => game.restartGame(),
                      );
                    } else {
                      game.restartGame();
                    }
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
                    if (AdManager.instance.canShowGameOverAd()) {
                      AdManager.instance.showInterstitialAd(
                        onAdClosed: () => Navigator.pop(context),
                      );
                    } else {
                      Navigator.pop(context);
                    }
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

  Widget _buildSuccessModal(BuildContext context, GameProvider game) {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Center(
        child: _MenuCard(
          title: "LEVEL UP!",
          titleColor: const Color(0xFFD84315), // Vibrant Orange/Red
          children: [
            const SizedBox(height: 20),
            // Trophy Visuals
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                      FontAwesomeIcons.trophy,
                      color: Color(0xFFFFD54F),
                      size: 100,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .rotate(
                      begin: -0.05,
                      end: 0.05,
                      duration: 1.5.seconds,
                      curve: Curves.easeInOut,
                    )
                    .animate()
                    .shimmer(duration: 2.seconds, color: Colors.white)
                    .scale(duration: 500.ms, curve: Curves.easeOutBack),
                // Confetti-like bits around trophy
                ...List.generate(8, (i) {
                  final angle = (i * 45) * (pi / 180);
                  return Transform.translate(
                        offset: Offset(cos(angle) * 70, sin(angle) * 70),
                        child: const Icon(
                          FontAwesomeIcons.star,
                          color: Color(0xFFFFD54F),
                          size: 12,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: (800 + (i * 100)).ms,
                        begin: const Offset(0, 0),
                        end: const Offset(1.5, 1.5),
                        curve: Curves.easeOutBack,
                      )
                      .fadeOut();
                }),
              ],
            ),

            const SizedBox(height: 32),

            // Level Text
            Text(
              "LEVEL ${game.level} COMPLETE",
              style: AppTheme.titleStyle.copyWith(
                fontSize: 20,
                color: const Color(0xFF3E2723),
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Simple, Elegant Stat Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSimpleStat("SCORE", game.score.toString()),
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.black.withValues(alpha: 0.1),
                ),
                _buildSimpleStat("COINS", "+${game.levelCoins}"),
              ],
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

            const SizedBox(height: 48),

            _LargeMenuButton(
              label: "NEXT LEVEL",
              icon: FontAwesomeIcons.circleArrowRight,
              onPressed: () {
                context.read<AudioProvider>().playSoundEffect(
                  SoundEffect.buttonClick,
                );
                game.acknowledgeLevelUp();
              },
              color: const Color(0xFF4CAF50), // Vibrant Green
            ).animate().fadeIn(delay: 800.ms).scale(curve: Curves.easeOutBack),
          ],
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5D4037).withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.titleStyle.copyWith(
            fontSize: 28,
            color: const Color(0xFF3E2723),
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
        width: double.infinity, // Changed to fill available space
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFFB74D), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.buttonStyle.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
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

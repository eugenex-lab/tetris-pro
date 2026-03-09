import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  void _startAppFlow() {
    // We wait 4 seconds for the splash animation to play then navigate
    Timer(const Duration(seconds: 4), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background texture/gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.background,
                  AppTheme.surface,
                  AppTheme.background,
                ],
              ),
            ),
          ),

          // Logo Center
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                      "TETRIS",
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 72,
                        color: AppTheme.primary,
                        letterSpacing: 8,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: -0.2, end: 0, curve: Curves.easeOutBack),

                Text(
                      "PRO",
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 84,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w900,
                        height: 0.8,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 800.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.elasticOut,
                    )
                    .shimmer(delay: 1500.ms, duration: 1500.ms),

                const SizedBox(height: 24),

                Container(
                  height: 4,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate().fadeIn(delay: 800.ms).scaleX(begin: 0, end: 1),
              ],
            ),
          ),

          // Creative Tetris Loading Animation at Bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tetris Blocks "Filling Up" animation
                    _buildTetrisLoading(),
                    const SizedBox(height: 12),
                    Text(
                          "PREPARING YOUR BLOCKS...",
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            letterSpacing: 3,
                            color: AppTheme.accent.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w900,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(duration: 600.ms)
                        .fadeOut(delay: 1000.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTetrisLoading() {
    const double blockSize = 14.0;
    const double spacing = 2.0;

    // Define some classic Tetris shapes as offsets
    final shapes = [
      [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(2, 0),
        const Offset(3, 0),
      ], // I
      [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(0, 1),
        const Offset(1, 1),
      ], // O
      [
        const Offset(1, 0),
        const Offset(0, 1),
        const Offset(1, 1),
        const Offset(2, 1),
      ], // T
      [
        const Offset(0, 0),
        const Offset(0, 1),
        const Offset(1, 1),
        const Offset(2, 1),
      ], // L
    ];

    final colors = [Colors.cyan, Colors.yellow, Colors.purple, Colors.orange];

    return SizedBox(
      height: blockSize * 5,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(shapes.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing * 3),
              child: _buildFallingShape(shapes[index], colors[index], index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFallingShape(List<Offset> blocks, Color color, int index) {
    const double size = 10.0;
    const double gap = 1.0;

    return SizedBox(
      width: size * 3,
      height: size * 4,
      child:
          Stack(
                children: blocks.map((offset) {
                  return Positioned(
                    left: offset.dx * size,
                    top: offset.dy * size,
                    child: Container(
                      width: size - gap,
                      height: size - gap,
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
                      ),
                    ),
                  );
                }).toList(),
              )
              .animate(onPlay: (c) => c.repeat())
              .moveY(
                begin: -60,
                end: 0,
                duration: 600.ms,
                delay: (index * 600).ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 300.ms)
              .then(delay: 2000.ms)
              .fadeOut(duration: 400.ms),
    );
  }
}

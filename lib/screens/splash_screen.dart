import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/services/ad_manager.dart';
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
    // We wait 3 seconds for the splash animation to play
    // Then we check if an App Open ad is ready
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      // Attempt to show App Open ad on cold start
      AdManager.instance.showAppOpenAd(
        onAdClosed: () {
          _navigateToHome();
        },
      );

      // Safety timeout: In case the ad manager doesn't trigger correctly or ad is null
      // We check if we already navigated to avoid double navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _navigateToHome();
        }
      });
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

          // Banner Ad at Bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                          "LOADING ASSETS...",
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(duration: 1000.ms)
                        .fadeOut(delay: 500.ms),
                    const SizedBox(height: 20),
                    Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      child: AdManager.instance.buildBannerWidget(
                        AdBannerType.home,
                      ),
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
}

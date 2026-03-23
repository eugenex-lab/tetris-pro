import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../core/app_theme.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({super.key, required this.onComplete});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'WELCOME TO TETRIS PRO',
      'icon': FontAwesomeIcons.gamepad,
      'description': 'Stack the blocks to clear lines and reach the highest score!',
      'controls': [
        {'icon': Icons.swipe_left_alt, 'label': 'Swipe Left/Right to Move'},
        {'icon': Icons.touch_app, 'label': 'Tap anywhere to Rotate'},
        {'icon': Icons.swipe_down_alt, 'label': 'Swipe Down to Drop Faster'},
      ],
    },
    {
      'title': 'SPEED IT UP',
      'icon': FontAwesomeIcons.bolt,
      'description': 'Master the drop speeds for better control.',
      'controls': [
        {'icon': Icons.swipe_down_alt, 'label': 'Swipe Down for Soft Drop'},
        {'icon': Icons.keyboard_double_arrow_down, 'label': 'Flick Down (Fast) for Hard Drop'},
      ],
    },
    {
      'title': 'PRO TIPS',
      'icon': FontAwesomeIcons.lightbulb,
      'description': 'Use these features to plan your strategy.',
      'controls': [
        {'icon': FontAwesomeIcons.ghost, 'label': 'Ghost Piece shows where it lands'},
        {'icon': FontAwesomeIcons.box, 'label': 'Hold Piece to save it for later'},
      ],
    },
    {
      'title': 'READY?',
      'icon': FontAwesomeIcons.circlePlay,
      'description': "Clear lines to earn coins and level up. Good luck!",
      'controls': [],
    },
  ];

  void _nextPage() {
    context.read<AudioProvider>().playSoundEffect(SoundEffect.buttonClick);
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                page['icon'],
                color: const Color(0xFFFFD54F),
                size: 48,
              ),
            ).animate(key: ValueKey('icon_$_currentPage'))
             .scale(duration: 400.ms, curve: Curves.easeOutBack)
             .fadeIn(),

            const SizedBox(height: 32),

            // Title
            Text(
              page['title'],
              textAlign: TextAlign.center,
              style: AppTheme.titleStyle.copyWith(
                color: const Color(0xFFFFD54F),
                fontSize: 28,
                letterSpacing: 2,
              ),
            ).animate(key: ValueKey('title_$_currentPage'))
             .slideY(begin: 0.2, duration: 400.ms)
             .fadeIn(),

            const SizedBox(height: 16),

            // Description
            Text(
              page['description'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ).animate(key: ValueKey('desc_$_currentPage'))
             .fadeIn(delay: 200.ms),

            const SizedBox(height: 40),

            // Controls
            ...List.generate(page['controls'].length, (index) {
              final control = page['controls'][index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(control['icon'], color: const Color(0xFFFFD54F), size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        control['label'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().slideX(begin: 0.1, delay: (300 + index * 100).ms).fadeIn(),
              );
            }),

            const SizedBox(height: 48),

            // Button
            GestureDetector(
              onTap: _nextPage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _currentPage == _pages.length - 1 ? "GOT IT!" : "NEXT",
                    style: const TextStyle(
                      color: Color(0xFF3E2723),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).scale(delay: 600.ms),

            const SizedBox(height: 24),

            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  width: index == _currentPage ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? const Color(0xFFFFD54F)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

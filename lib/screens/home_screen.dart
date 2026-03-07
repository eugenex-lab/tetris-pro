import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/screens/game_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tetris_pro/screens/settings_screen.dart';
import 'package:tetris_pro/services/ad_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access provider for stats
    final game = context.watch<GameProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE6D4B2), // Light Wood Background
          image: DecorationImage(
            image: NetworkImage(
              'https://www.transparenttextures.com/patterns/wood-pattern.png',
            ), // Subtle texture if internet available, else fallback to color
            opacity: 0.1,
            scale: 2.0,
          ),
        ),
        // Overriding the decoration to be safer and simpler without external assets for now
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE8DABA),
                const Color(0xFFDCC6A0),
                const Color(0xFFE8DABA),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Restored Yellow Coin Button
                      _buildTopPill(
                        icon: FontAwesomeIcons.coins,
                        color: const Color(0xFFFFD54F),
                        text: "${game.coins}",
                        isCoin: true,
                      ),
                      // Settings
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF4E342E),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Color(0xFFD7CCC8),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Logo Area
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "TETRIS",
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 56, // Adjusted size
                        color: const Color(0xFF3E2723),
                        height: 0.9,
                        shadows: [],
                      ),
                    ),
                    Text(
                      "PRO",
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 64,
                        color: const Color(0xFF3E2723),
                        height: 0.9,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(2, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E2723).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Transform.rotate(
                          angle: -0.05,
                          child: _buildStatBox(
                            label: "LEVEL",
                            value: "${game.level}",
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Transform.rotate(
                          angle: 0.05,
                          child: _buildStatBox(
                            label: "BEST",
                            value: "${game.highScore}",
                            valueColor: const Color(0xFFFFD54F), // Gold color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Center Play Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                  child: Container(
                    width: 140, // Slightly bigger
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 10),
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF8D6E63,
                          ), // Lighter top edge highlight
                          offset: const Offset(0, -4),
                          blurRadius: 0,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                            width: 3,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF5D4037),
                              const Color(0xFF3E2723),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 70,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Side Buttons (Settings, etc - repurposed)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Button (Stats/Leaderboard)
                      _buildSquareButton(
                        icon: Icons.bar_chart_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Leaderboard coming soon!"),
                            ),
                          );
                        },
                      ),

                      // Right Button (Awards/Skins)
                      _buildSquareButton(
                        icon: FontAwesomeIcons.ribbon, // Or similar
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Skins coming soon!")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Banner Ad
                AdManager.instance.buildBannerWidget(AdBannerType.home),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPill({
    required IconData icon,
    required Color color,
    required String text,
    bool isCoin = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F), // Premium Yellow
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8B000), // Darker yellow stroke
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF3E2723), size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF3E2723),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF3E2723), // Darker wood for plaque look
        // Remove border radius to make it look like a cut piece of wood? Or smaller radius.
        // User wants it to look like a label, so flat or inset.
        // Let's try a distinct shape or just darkened background without big elevation.
        image: const DecorationImage(
          image: NetworkImage(
            'https://www.transparenttextures.com/patterns/wood-pattern.png',
          ),
          opacity: 0.05,
          fit: BoxFit.cover,
        ),
        boxShadow: [
          // Basic shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(2, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFD7CCC8).withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF4E342E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFFD7CCC8), size: 24),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/screens/game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A120B), // Darker black
              const Color(0xFF2D2620), // Warm dark wood
              const Color(0xFF1A120B), // Back to dark
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/wood_grain.png'),
                      repeat: ImageRepeat.repeat,
                      scale: 2.0,
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with glow
                    Container(
                      margin: const EdgeInsets.only(bottom: 60),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Text(
                            "TETRIS PRO",
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 56,
                              color: const Color(0xFFFFD54F),
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFFFFD54F,
                                  ).withOpacity(0.4),
                                  blurRadius: 30,
                                ),
                                Shadow(
                                  color: const Color(
                                    0xFFFFD54F,
                                  ).withOpacity(0.2),
                                  blurRadius: 50,
                                ),
                              ],
                            ),
                          ),
                          // Main text
                          Text(
                            "TETRIS PRO",
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 56,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Play button (larger and more prominent)
                    Container(
                      width: 280,
                      height: 70,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: _buildMenuButton(
                        context,
                        "PLAY NOW",
                        Icons.play_arrow_rounded,
                        const Color(0xFFFFB74D),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GameScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Other buttons
                    Container(
                      width: 240,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: _buildMenuButton(
                        context,
                        "SKIN SHOP",
                        Icons.palette,
                        const Color(0xFF8D6E63),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Coming Soon!"),
                              backgroundColor: Color(0xFF5D4037),
                            ),
                          );
                        },
                      ),
                    ),

                    Container(
                      width: 240,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: _buildMenuButton(
                        context,
                        "LEADERBOARD",
                        Icons.leaderboard,
                        const Color(0xFF78909C),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Coming Soon!"),
                              backgroundColor: Color(0xFF5D4037),
                            ),
                          );
                        },
                      ),
                    ),

                    Container(
                      width: 240,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: _buildMenuButton(
                        context,
                        "SETTINGS",
                        Icons.settings,
                        const Color(0xFF546E7A),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Coming Soon!"),
                              backgroundColor: Color(0xFF5D4037),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Footer text
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Classic Tetris • Modern Experience",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      const Color(0xFF2D2620),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: accentColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: AppTheme.buttonStyle.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
        
    );
  }
}

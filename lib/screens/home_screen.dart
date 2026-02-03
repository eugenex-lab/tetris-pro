import 'package:flutter/material.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/screens/game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.woodDark,
                AppTheme.background,
              ]),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("TETRIS PRO", style: AppTheme.titleStyle.copyWith(fontSize: 48)),
              const SizedBox(height: 50),
              _buildMenuButton(context, "PLAY", () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const GameScreen()));
              }),
              const SizedBox(height: 20),
              _buildMenuButton(context, "SKINS", () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
              }),
              const SizedBox(height: 20),
              _buildMenuButton(context, "LEADERBOARD", () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, VoidCallback onTap) {
      return SizedBox(
          width: 200,
          height: 60,
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.woodLight,
                  foregroundColor: AppTheme.woodDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 5,
              ),
              onPressed: onTap,
              child: Text(label, style: AppTheme.buttonStyle),
          ),
      );
  }
}

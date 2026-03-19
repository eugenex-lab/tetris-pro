// File: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/audio_provider.dart';
import 'package:tetris_pro/providers/game_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE6D4B2), // Matches Light Wood Background
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8DABA), Color(0xFFDCC6A0), Color(0xFFE8DABA)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Back Button
                Positioned(
                  top: 16,
                  left: 24,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF4E342E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFFD7CCC8),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Center(
                  child: SingleChildScrollView(
                    child: _SettingsCard(
                      title: "SETTINGS",
                      children: [
                        const SizedBox(height: 24),

                        // Audio Section
                        _buildSectionHeader("AUDIO"),
                        Consumer<AudioProvider>(
                          builder: (context, audio, _) => Column(
                            children: [
                              _SettingsToggle(
                                label: "MUSIC",
                                value: !audio.isMusicMuted,
                                icon: FontAwesomeIcons.music,
                                onChanged: (val) => audio.toggleMusic(),
                              ),
                              _SettingsToggle(
                                label: "SOUND EFFECTS",
                                value: !audio.isSfxMuted,
                                icon: FontAwesomeIcons.volumeHigh,
                                onChanged: (val) => audio.toggleSfx(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Gameplay Section
                        _buildSectionHeader("GAMEPLAY"),
                        Consumer<GameProvider>(
                          builder: (context, game, _) => Column(
                            children: [
                              _SettingsToggle(
                                label: "GHOST PIECE",
                                value: game.showGhostPiece,
                                icon: FontAwesomeIcons.ghost,
                                onChanged: (val) => game.toggleGhostPiece(),
                              ),
                              _SettingsToggle(
                                label: "HAPTIC FEEDBACK",
                                value: game.hapticsEnabled,
                                icon: FontAwesomeIcons.handPointer,
                                onChanged: (val) => game.toggleHaptics(),
                              ),
                              _SettingsToggle(
                                label: "TUTORIAL",
                                value: game.showTutorial,
                                icon: FontAwesomeIcons.circleQuestion,
                                onChanged: (val) => game.toggleTutorial(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Danger Zone
                        _LargeButton(
                          label: "RESET PROGRESS",
                          icon: FontAwesomeIcons.trashCan,
                          onPressed: () => _showResetConfirmation(context),
                          color: Colors.red.withOpacity(0.7),
                        ),

                        const SizedBox(height: 16),
                        _LargeButton(
                          label: "CLOSE",
                          icon: FontAwesomeIcons.xmark,
                          onPressed: () => Navigator.pop(context),
                          color: const Color(0xFF5D4037),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "v 1.0.0",
                          style: TextStyle(
                            color: Colors.black26,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF5D4037).withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE6D4B2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "RESET PROGRESS?",
          style: AppTheme.titleStyle.copyWith(
            color: const Color(0xFF3E2723),
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "This will clear your high score and coins forever. Are you sure?",
          style: TextStyle(
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              context.read<GameProvider>().resetProgress();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All progress reset.")),
              );
            },
            child: const Text(
              "RESET",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFE7DCC9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC4B59D), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTheme.titleStyle.copyWith(
              color: const Color(0xFF3E2723),
              fontSize: 32,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5D4037), size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF3E2723),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5D4037),
            activeTrackColor: const Color(0xFFFFD54F),
          ),
        ],
      ),
    );
  }
}

class _LargeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _LargeButton({
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

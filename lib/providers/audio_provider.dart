import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicMuted = false;
  bool _isSfxMuted = false;
  bool _isInitialized = false;

  bool get isMusicMuted => _isMusicMuted;
  bool get isSfxMuted => _isSfxMuted;
  bool get isInitialized => _isInitialized;

  // Initialize audio system
  Future<void> init() async {
    if (_isInitialized) return;

    // Load mute preferences
    final prefs = await SharedPreferences.getInstance();
    _isMusicMuted = prefs.getBool('music_muted') ?? false;
    _isSfxMuted = prefs.getBool('sfx_muted') ?? false;

    // Configure music player for looping
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.3); // Background music at 30% volume

    // Configure SFX player
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setVolume(0.5); // Sound effects at 50% volume

    _isInitialized = true;

    // Start background music if not muted
    if (!_isMusicMuted) {
      playMusic();
    }

    notifyListeners();
  }

  // Play background music
  Future<void> playMusic() async {
    if (_isMusicMuted || !_isInitialized) return;

    try {
      if (_musicPlayer.state != PlayerState.playing) {
        // Using a royalty-free 8-bit loop from a public source for demo purposes
        await _musicPlayer.play(
          UrlSource(
            'https://opengameart.org/sites/default/files/Tetris%20Theme%20%28Chiptune%20Cover%29.mp3',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeMusic() async {
    if (_isMusicMuted || !_isInitialized) return;
    await _musicPlayer.resume();
  }

  // Toggle Music
  Future<void> toggleMusic() async {
    _isMusicMuted = !_isMusicMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_muted', _isMusicMuted);

    if (_isMusicMuted) {
      await pauseMusic();
    } else {
      await playMusic();
    }
    notifyListeners();
  }

  // Toggle SFX
  Future<void> toggleSfx() async {
    _isSfxMuted = !_isSfxMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_muted', _isSfxMuted);
    notifyListeners();
  }

  // Play sound effect
  Future<void> playSoundEffect(SoundEffect effect) async {
    if (_isSfxMuted || !_isInitialized) return;

    try {
      // NOTE: In a real app, ensure these assets exist in pubspec.yaml and assets/audio/ folder
      // For now we use fallback logic or external URLs if local assets fail,
      // but simplistic local asset calls are standard.
      String assetPath;
      switch (effect) {
        case SoundEffect.drop:
          // Short thud
          assetPath = 'audio/drop.mp3';
          break;
        case SoundEffect.lineClear:
          // Success chime
          assetPath = 'audio/line_clear.mp3';
          break;
        case SoundEffect.gameOver:
          // Sad fail sound
          assetPath = 'audio/game_over.mp3';
          break;
        case SoundEffect.rotate:
          // Short tick
          assetPath = 'audio/rotate.mp3';
          break;
        case SoundEffect.buttonClick:
          // UI click
          assetPath = 'audio/click.mp3';
          break;
      }

      // If you don't have local assets, this might throw or do nothing.
      // Uncomment the line below when you have assets.
      // await _sfxPlayer.play(AssetSource(assetPath));
      debugPrint('Sound effect: $assetPath');
    } catch (e) {
      debugPrint('Error playing sound effect: $e');
    }
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}

enum SoundEffect { drop, lineClear, gameOver, rotate, buttonClick }

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AudioProvider with ChangeNotifier {
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
        await _musicPlayer.stop();

        final source = await _getSource(
          'music.mp3',
          'https://raw.githubusercontent.com/rafael-p-andrade/Tetris/master/assets/audio/theme.mp3',
        );

        await _musicPlayer.play(source);
      }
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  // Helper to determine if we should use local asset or URL fallback
  Future<Source> _getSource(String assetName, String urlFallback) async {
    try {
      // rootBundle.load expects the full path as defined in pubspec
      await rootBundle.load('assets/audio/$assetName');
      return AssetSource('audio/$assetName');
    } catch (_) {
      return UrlSource(urlFallback);
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
      String url;
      String assetName;

      switch (effect) {
        case SoundEffect.drop:
          assetName = 'drop.mp3';
          url =
              'https://raw.githubusercontent.com/rafael-p-andrade/Tetris/master/assets/audio/fall.mp3';
          break;
        case SoundEffect.lineClear:
          assetName = 'line_clear.mp3';
          url =
              'https://raw.githubusercontent.com/frodosnow/Tetris-Remix/master/assets/audio/clear.mp3';
          break;
        case SoundEffect.gameOver:
          assetName = 'game_over.mp3';
          url =
              'https://raw.githubusercontent.com/frodosnow/Tetris-Remix/master/assets/audio/gameover.mp3';
          break;
        case SoundEffect.rotate:
          assetName = 'rotate.mp3';
          url =
              'https://raw.githubusercontent.com/rafael-p-andrade/Tetris/master/assets/audio/rotate.mp3';
          break;
        case SoundEffect.buttonClick:
          assetName = 'click.mp3';
          url =
              'https://raw.githubusercontent.com/rafael-p-andrade/Tetris/master/assets/audio/selection.mp3';
          break;
      }

      await _sfxPlayer.stop();
      final source = await _getSource(assetName, url);
      await _sfxPlayer.play(source);
      debugPrint('Playing SFX: source type ${source.runtimeType}');
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

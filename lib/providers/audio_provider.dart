import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;
  bool _isInitialized = false;

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;

  // Initialize audio system
  Future<void> init() async {
    if (_isInitialized) return;

    // Load mute preference
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('audio_muted') ?? false;

    // Configure music player for looping
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.3); // Background music at 30% volume

    // Configure SFX player
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setVolume(0.5); // Sound effects at 50% volume

    _isInitialized = true;

    // Start background music if not muted
    if (!_isMuted) {
      await playMusic();
    }

    notifyListeners();
  }

  // Play background music
  Future<void> playMusic() async {
    if (_isMuted || !_isInitialized) return;

    try {
      // For now, using a placeholder. Replace with actual asset path
      // await _musicPlayer.play(AssetSource('audio/background_music.mp3'));

      // Temporary: play a simple tone or use a URL
      // You can replace this with an actual asset once you have the audio file
      debugPrint('Background music would play here (asset not yet added)');
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  // Pause background music
  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  // Resume background music
  Future<void> resumeMusic() async {
    if (_isMuted || !_isInitialized) return;
    await _musicPlayer.resume();
  }

  // Toggle mute state
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_muted', _isMuted);

    // Update music playback
    if (_isMuted) {
      await pauseMusic();
    } else {
      await playMusic();
    }

    notifyListeners();
  }

  // Play sound effect
  Future<void> playSoundEffect(SoundEffect effect) async {
    if (_isMuted || !_isInitialized) return;

    try {
      String assetPath;
      switch (effect) {
        case SoundEffect.drop:
          assetPath = 'audio/drop.mp3';
          break;
        case SoundEffect.lineClear:
          assetPath = 'audio/line_clear.mp3';
          break;
        case SoundEffect.gameOver:
          assetPath = 'audio/game_over.mp3';
          break;
        case SoundEffect.rotate:
          assetPath = 'audio/rotate.mp3';
          break;
      }

      // await _sfxPlayer.play(AssetSource(assetPath));
      debugPrint('Sound effect would play: $assetPath (asset not yet added)');
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

enum SoundEffect { drop, lineClear, gameOver, rotate }

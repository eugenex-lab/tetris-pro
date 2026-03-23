import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/providers/audio_provider.dart';
import 'package:tetris_pro/services/ad_manager.dart';
import 'package:tetris_pro/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  // Initialize services here (Supabase, AdMob)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await MobileAds.instance.initialize();

  // Initialize AdManager (after dotenv is loaded)
  AdManager.instance.initialize();

  runApp(const TetrisProApp());
}

class TetrisProApp extends StatelessWidget {
  const TetrisProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()..init()),
      ],
      child: AppLifecycleManager(
        child: MaterialApp(
          title: 'Tetris Pro',
          theme: AppTheme.themeData,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final audio = context.read<AudioProvider>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      audio.pauseMusic();
      AdManager.instance.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      audio.resumeMusic();
      AdManager.instance.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

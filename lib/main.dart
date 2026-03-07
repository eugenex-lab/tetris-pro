import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/providers/audio_provider.dart';
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

class TetrisProApp extends StatefulWidget {
  const TetrisProApp({super.key});

  @override
  State<TetrisProApp> createState() => _TetrisProAppState();
}

class _TetrisProAppState extends State<TetrisProApp>
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

    // Track app lifecycle for Smart App Open Ads
    if (state == AppLifecycleState.paused) {
      AdManager.instance.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AdManager.instance.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Tetris Pro',
        theme: AppTheme.themeData,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

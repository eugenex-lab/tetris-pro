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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:tetris_pro/services/notification_service.dart';
import 'package:tetris_pro/services/retention_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  // Initialize services here (Supabase, AdMob)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await MobileAds.instance.initialize();

  // Initialize NotificationService
  await NotificationService().init();

  // Refresh retention notifications
  await RetentionService().refreshSchedules();

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
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ],
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
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSession();
  }

  void _startSession() {
    _sessionStartTime = DateTime.now();
    FirebaseAnalytics.instance.logEvent(name: 'session_start');
    debugPrint('Analytics: session_start');
  }

  void _endSession() {
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      FirebaseAnalytics.instance.logEvent(
        name: 'session_end',
        parameters: {'duration_seconds': duration.inSeconds},
      );
      debugPrint('Analytics: session_end (${duration.inSeconds}s)');
      _sessionStartTime = null;
    }
  }

  @override
  void dispose() {
    _endSession();
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
      _endSession();
    } else if (state == AppLifecycleState.resumed) {
      audio.resumeMusic();
      AdManager.instance.onAppResumed();
      _startSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

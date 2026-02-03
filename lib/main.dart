import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tetris_pro/core/app_theme.dart';
import 'package:tetris_pro/providers/game_provider.dart';
import 'package:tetris_pro/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services here (Supabase, AdMob)
  await Supabase.initialize(
    url: 'https://ztkeqmhmszdacumpjyb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0a2VxbWh6bXN6ZGFjdW1wanliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDY4NjgsImV4cCI6MjA4NTcyMjg2OH0._5rfuJX6dWoYdNi0c2JABVAHuD2C-uYi7B0w6NWfvtY',
  );
  MobileAds.instance.initialize();

  runApp(const TetrisProApp());
}

class TetrisProApp extends StatelessWidget {
  const TetrisProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
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

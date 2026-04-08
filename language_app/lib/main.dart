import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BhashaSikhoApp());
}

class BhashaSikhoApp extends StatelessWidget {
  const BhashaSikhoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
      ),
      home: const _StartupRouter(),
    );
  }
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();
  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final language = prefs.getString('language');
    if (!mounted) return;
    if (userId != null && userId.isNotEmpty) {
      if (language != null) await TtsService.init(language);
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => HomeScreen(userId: userId)));
    } else {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LanguageScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('भा', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white)),
            SizedBox(height: 12),
            Text(AppStrings.appName, style: TextStyle(fontSize: 22, color: Colors.white70)),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
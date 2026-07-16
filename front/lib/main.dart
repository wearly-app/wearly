import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:wearly/config/app_config.dart';
import 'package:wearly/screens/home_screen.dart';
import 'package:wearly/screens/login_screen.dart';
import 'package:wearly/screens/splash_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized before calling KakaoSdk
  WidgetsFlutterBinding.ensureInitialized();

  // Web redirect check at the very entry point before routing strips the URL!
  if (kIsWeb) {
    final queryParams = Uri.base.queryParameters;
    if (queryParams.containsKey('code')) {
      final code = queryParams['code'];
      const storage = FlutterSecureStorage();
      await storage.write(key: 'wearly_redirect_code', value: code);
    }
  }

  // Initialize Kakao SDK
  await KakaoSdk.init(
    nativeAppKey: AppConfig.kakaoNativeAppKey,
    javaScriptAppKey: AppConfig.kakaoJavaScriptAppKey,
  );

  runApp(const WearlyApp());
}

class WearlyApp extends StatelessWidget {
  const WearlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wearly',
      debugShowCheckedModeBanner: false,
      
      // Global app theme setting (Slate/Indigo modern dark theme)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo accent
          secondary: Color(0xFFEC4899), // Pink accent
          background: Color(0xFF0F172A), // Slate 900
          surface: Color(0xFF1E293B), // Slate 800
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        fontFamily: 'Roboto', // Modern system font
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),

      // Start with the home screen directly during local development/testing
      initialRoute: '/home',
      
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

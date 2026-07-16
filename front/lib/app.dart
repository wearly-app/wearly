import 'package:front/screens/home_screen.dart';
import 'package:front/screens/login_screen.dart';
import 'package:front/screens/splash_screen.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/closet', // Starts directly on the dashboard
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/closet',
      builder: (context, state) => const ClosetMainPage(),
      routes: [
        GoRoute(
          path: 'codi-maker',
          builder: (context, state) => const CodiMakerPage(),
        ),
        GoRoute(
          path: 'saved-outfits',
          builder: (context, state) => const SavedOutfitsPage(),
        ),
        GoRoute(
          path: 'wardrobe',
          builder: (context, state) => const WardrobePage(),
        ),
        GoRoute(
          path: 'ai-recommendation',
          builder: (context, state) {
            final style = state.uri.queryParameters['style'] ?? '캐주얼';
            return AiLoadingPage(selectedStyle: style);
          },
        ),
      ],
    ),
  ],
);

class WearlyApp extends StatelessWidget {
  const WearlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '스마트 코디',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A1A1A),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
        ),
      ),
      routerConfig: _router,
    );
  }
}

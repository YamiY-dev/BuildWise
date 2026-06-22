import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'providers/app_state.dart';
import 'providers/build_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/builder/build_screen.dart';
import 'screens/builder/build_detail_screen.dart';
import 'screens/builder/my_builds_screen.dart';
import 'screens/components/component_list_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/community/user_profile_screen.dart';
import 'screens/ai/ai_assistant_screen.dart';
import 'screens/pricing/price_tracking_screen.dart';
import 'screens/challenges/challenges_screen.dart';
import 'screens/visual/visual_builder_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const PCBuilderApp());
}

class PCBuilderApp extends StatelessWidget {
  const PCBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => BuildProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'PC Builder Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/builder': (context) => const BuildScreen(),
              '/my-builds': (context) => const MyBuildsScreen(),
              '/components': (context) => const ComponentListScreen(),
              '/community': (context) => const CommunityScreen(),
              '/ai-assistant': (context) => const AIAssistantScreen(),
              '/price-tracking': (context) => const PriceTrackingScreen(),
              '/challenges': (context) => const ChallengesScreen(),
              '/visual-builder': (context) => const VisualBuilderScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/build-detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => BuildDetailScreen(build: args['build']),
                );
              }
              if (settings.name == '/user-profile') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => UserProfileScreen(userId: args['userId']),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth/auth_provider.dart';
import '../pages/auth/signup_page.dart';

/// Route paths
class Routes {
  Routes._();
  
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String journal = '/journal';
  static const String journalCreate = '/journal/create';
  static const String goals = '/goals';
  static const String goalCreate = '/goals/create';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == Routes.login || 
                          state.matchedLocation == Routes.signup;
      
      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute && state.matchedLocation != Routes.splash) {
        return Routes.login;
      }
      
      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return Routes.home;
      }
      
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      
      // Auth
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => const SignupPage(),
      ),
      
      // Main app with bottom navigation
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
      
      // Journal
      GoRoute(
        path: Routes.journal,
        builder: (context, state) => const JournalPage(),
      ),
      GoRoute(
        path: Routes.journalCreate,
        builder: (context, state) => const JournalCreatePage(),
      ),
      
      // Goals
      GoRoute(
        path: Routes.goals,
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: Routes.goalCreate,
        builder: (context, state) => const GoalCreatePage(),
      ),
      
      // Profile & Settings
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

// Placeholder pages - these will be implemented
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ClarityLog', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(Routes.signup),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home - Coming Soon')),
    );
  }
}

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Journals - Coming Soon')),
    );
  }
}

class JournalCreatePage extends StatelessWidget {
  const JournalCreatePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Create Journal - Coming Soon')),
    );
  }
}

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Goals - Coming Soon')),
    );
  }
}

class GoalCreatePage extends StatelessWidget {
  const GoalCreatePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Create Goal - Coming Soon')),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Settings - Coming Soon')),
    );
  }
}
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile - Coming Soon')),
    );
  }
}

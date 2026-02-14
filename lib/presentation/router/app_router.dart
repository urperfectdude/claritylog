import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth/auth_provider.dart';
import '../pages/auth/signup_page.dart';
import '../pages/home/home_page.dart';
import '../pages/journal/journal_list_page.dart';
import '../pages/journal/journal_create_page.dart';
import '../pages/goals/goals_list_page.dart';
import '../pages/goals/goal_create_page.dart';
import '../pages/settings/profile_page.dart';

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
        builder: (context, state) => const JournalListPage(),
      ),
      GoRoute(
        path: Routes.journalCreate,
        builder: (context, state) => const JournalCreatePage(),
      ),
      
      // Goals
      GoRoute(
        path: Routes.goals,
        builder: (context, state) => const GoalsListPage(),
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

// Splash page - checks auth and redirects
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Auto-redirect based on auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.status != AuthStatus.initial && authState.status != AuthStatus.loading) {
        if (authState.isAuthenticated) {
          context.go(Routes.home);
        } else {
          context.go(Routes.login);
        }
      }
    });
    
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ClarityLog',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Login page
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    await ref.read(authProvider.notifier).signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ClarityLog',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your AI-powered productivity companion',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Reset password
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => context.go(Routes.signup),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Settings page placeholder
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings - Coming Soon')),
    );
  }
}

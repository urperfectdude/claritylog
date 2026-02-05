import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/models.dart';

/// Auth state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth provider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initialize();
  }

  final _supabase = SupabaseConfig.client;

  void _initialize() {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _handleSignedIn(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });

    // Check initial session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _handleSignedIn(session.user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _handleSignedIn(User user) async {
    state = state.copyWith(status: AuthStatus.loading, user: user);

    try {
      // Fetch or create user profile
      final profileData = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      UserProfile profile;
      if (profileData != null) {
        profile = UserProfile.fromSupabase(profileData);
      } else {
        // Create new profile
        profile = UserProfile.fromAuthUser(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'] as String?,
        );
        await _supabase.from('user_profiles').insert(profile.toSupabase());
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        profile: profile,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: 'Failed to load profile',
      );
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password, {String? name}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'full_name': name} : null,
      );
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.productivity.mindflow://login-callback',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Google sign-in failed',
      );
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.productivity.mindflow://login-callback',
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Apple sign-in failed',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  /// Update profile
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('user_profiles')
          .update(profile.toSupabase())
          .eq('id', profile.id);
      state = state.copyWith(profile: profile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update profile');
    }
  }
}

/// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).profile;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

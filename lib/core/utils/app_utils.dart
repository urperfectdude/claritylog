import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/env.dart';

/// Network status utility
class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();

  /// Initialize network monitoring
  static void init() {
    // Start monitoring connectivity
  }

  /// Check if device is online
  static Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }
}

/// Supabase client singleton
class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Get current user ID or null
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;
}

/// Alias for SupabaseConfig.initialize
class SupabaseUtils {
  static Future<void> init() => SupabaseConfig.initialize();
}

/// Hive configuration and initialization
class HiveConfig {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters (will be generated)
    // Hive.registerAdapter(JournalAdapter());
    // Hive.registerAdapter(GoalAdapter());
    // Hive.registerAdapter(UserProfileAdapter());
    // Hive.registerAdapter(SyncItemAdapter());

    // Open boxes
    await Future.wait([
      Hive.openBox(AppConstants.userBoxName),
      Hive.openBox(AppConstants.journalBoxName),
      Hive.openBox(AppConstants.goalsBoxName),
      Hive.openBox(AppConstants.settingsBoxName),
      Hive.openBox(AppConstants.syncQueueBoxName),
    ]);
  }

  /// Get a box by name
  static Box getBox(String name) => Hive.box(name);

  /// Get settings box
  static Box get settingsBox => Hive.box(AppConstants.settingsBoxName);

  /// Get sync queue box
  static Box get syncQueueBox => Hive.box(AppConstants.syncQueueBoxName);
}

/// Alias for HiveConfig.initialize
class HiveUtils {
  static Future<void> init() => HiveConfig.initialize();
}

/// UUID generator
class UuidGenerator {
  static String generate() {
    // Simple UUID v4 implementation
    const chars = '0123456789abcdef';
    final random = DateTime.now().millisecondsSinceEpoch;
    final uuid = StringBuffer();

    for (var i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        uuid.write('-');
      } else if (i == 14) {
        uuid.write('4');
      } else if (i == 19) {
        uuid.write(chars[(random & 0x3) | 0x8]);
      } else {
        uuid.write(chars[(random + i) % 16]);
      }
    }

    return uuid.toString();
  }
}

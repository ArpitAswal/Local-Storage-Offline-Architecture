import 'package:flutter/material.dart';
import '../views/shared_pref_screen.dart';
import '../views/hive_screen.dart';
import '../views/isar_screen.dart';
import '../views/secure_storage_screen.dart';
import '../views/drift_screen.dart';
import '../views/sql_lite_screen.dart';
import '../views/offline_cache_screen.dart';

/// [RouteNavigation] - A clean wrapper around Flutter's Navigator system.
/// Keeps route builders separated from views for better architecture compliance.
class RouteNavigation {
  // Private constructor to prevent instantiation
  RouteNavigation._();

  /// Navigates to the Shared Preferences dashboard.
  static void toSharedPrefs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SharedPreferenceScreen()),
    );
  }

  /// Navigates to the Hive dashboard.
  static void toHive(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HiveScreen()),
    );
  }

  /// Navigates to the Isar dashboard.
  static void toIsar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IsarScreen()),
    );
  }

  /// Navigates to the Secure Storage dashboard.
  static void toSecureStorage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecureStorageScreen()),
    );
  }

  /// Navigates to the SQLite dashboard.
  static void toSqlite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SqlLiteScreen()),
    );
  }

  /// Navigates to the Drift dashboard.
  static void toDrift(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DriftScreen()),
    );
  }

  /// Navigates to the Offline Cache & Repository dashboard.
  static void toOfflineCache(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OfflineCacheScreen()),
    );
  }

  /// Pops the current screen off the navigation stack.
  static void back(BuildContext context) {
    Navigator.pop(context);
  }

  /// Dynamic navigation helper to push any generic screen widget.
  static void push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

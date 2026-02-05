import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as "Today", "Yesterday", or "Jan 15"
  String get relativeDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(year, month, day);

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (now.difference(this).inDays < 7) {
      return DateFormat.EEEE().format(this); // "Monday"
    } else {
      return DateFormat.MMMd().format(this); // "Jan 15"
    }
  }

  /// Format as "2:30 PM"
  String get timeOnly => DateFormat.jm().format(this);

  /// Format as "Jan 15, 2024"
  String get dateFormatted => DateFormat.yMMMd().format(this);

  /// Format as "January 15, 2024 at 2:30 PM"
  String get fullFormatted => DateFormat.yMMMMd().add_jm().format(this);

  /// Check if same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncate with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Check if valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Parse to DateTime or null
  DateTime? toDateTime() => DateTime.tryParse(this);
}

/// BuildContext extensions
extension ContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  /// Show loading dialog
  Future<void> showLoadingDialog({String? message}) {
    return showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    Navigator.of(this).pop();
  }
}

/// num extensions
extension NumExtensions on num {
  /// Convert to Duration in milliseconds
  Duration get ms => Duration(milliseconds: toInt());

  /// Convert to Duration in seconds
  Duration get seconds => Duration(seconds: toInt());

  /// Convert to Duration in minutes
  Duration get minutes => Duration(minutes: toInt());

  /// Convert to Duration in hours
  Duration get hours => Duration(hours: toInt());
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Safe get at index
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Separate list into chunks
  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

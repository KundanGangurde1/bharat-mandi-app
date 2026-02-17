import 'package:flutter/material.dart';

/// ✅ Centralized error handling to ensure consistent error messages
/// Used across all form screens and report screens
class ErrorHandler {
  /// Show error snackbar with consistent styling
  /// 
  /// Parameters:
  /// - context: BuildContext for showing snackbar
  /// - error: The error message or exception
  /// - title: Optional title prefix (e.g., 'Farmer Load Error')
  /// - showDebugInfo: Whether to print debug info to console
  static void showError(
    BuildContext context,
    dynamic error, {
    String? title,
    bool showDebugInfo = true,
  }) {
    final message = _formatErrorMessage(error, title);

    if (showDebugInfo) {
      print('❌ $message');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success snackbar
  /// 
  /// Parameters:
  /// - context: BuildContext for showing snackbar
  /// - message: Success message
  /// - duration: How long to show (default 2 seconds)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    print('✅ $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show warning snackbar
  /// 
  /// Parameters:
  /// - context: BuildContext for showing snackbar
  /// - message: Warning message
  static void showWarning(
    BuildContext context,
    String message,
  ) {
    print('⚠️ $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show info snackbar
  /// 
  /// Parameters:
  /// - context: BuildContext for showing snackbar
  /// - message: Info message
  static void showInfo(
    BuildContext context,
    String message,
  ) {
    print('ℹ️ $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Handle error in async operation with try-catch pattern
  /// 
  /// Usage:
  /// ```dart
  /// try {
  ///   // Do something
  /// } catch (e) {
  ///   ErrorHandler.handleAsyncError(context, e, 'Loading Data');
  /// }
  /// ```
  static void handleAsyncError(
    BuildContext context,
    dynamic error, {
    String? operation,
  }) {
    final title = operation != null ? '$operation Error' : null;
    showError(context, error, title: title);
  }

  /// Format error message for display
  /// 
  /// Converts exception objects to readable strings
  static String _formatErrorMessage(dynamic error, String? title) {
    String message = '';

    // Add title if provided
    if (title != null && title.isNotEmpty) {
      message = '$title: ';
    }

    // Format error based on type
    if (error is Exception) {
      message += error.toString().replaceFirst('Exception: ', '');
    } else if (error is String) {
      message += error;
    } else {
      message += error.toString();
    }

    // Fallback to generic message if empty
    if (message.isEmpty) {
      message = 'अनपेक्षित त्रुटी आली';
    }

    return message;
  }

  /// Log error to console with context
  /// 
  /// Parameters:
  /// - message: Error message
  /// - error: The exception/error object
  /// - stackTrace: Optional stack trace
  static void logError(
    String message,
    dynamic error, {
    StackTrace? stackTrace,
  }) {
    print('❌ $message');
    print('   Error: $error');
    if (stackTrace != null) {
      print('   Stack: $stackTrace');
    }
  }

  /// Show dialog for critical errors
  /// 
  /// Parameters:
  /// - context: BuildContext
  /// - title: Dialog title
  /// - message: Error message
  /// - onRetry: Callback when user taps retry
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('पुन्हा प्रयत्न करा'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('बंद करा'),
          ),
        ],
      ),
    );
  }

  /// Validate context is mounted before showing snackbar
  /// 
  /// Usage:
  /// ```dart
  /// if (ErrorHandler.isContextValid(context)) {
  ///   ErrorHandler.showError(context, error);
  /// }
  /// ```
  static bool isContextValid(BuildContext context) {
    try {
      ScaffoldMessenger.of(context);
      return true;
    } catch (e) {
      print('⚠️ Context is not valid for showing snackbar');
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:restart_app/restart_app.dart';

/// Result of an update attempt. [errorMessage] is null on success.
typedef UpdateResult = ({bool success, String? errorMessage});

class UpdateService {
  static final ShorebirdUpdater _updater = ShorebirdUpdater();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!_updater.isAvailable) {
      debugPrint('Shorebird is not available - running in debug mode or non-Shorebird build');
      _isInitialized = true;
      return;
    }

    try {
      final currentPatch = await _updater.readCurrentPatch();
      debugPrint('Current patch: ${currentPatch?.number ?? 'No patch installed'}');
    } catch (e) {
      debugPrint('Error reading current patch: $e');
    }

    _isInitialized = true;
  }

  static Future<bool> checkForUpdates() async {
    if (!_updater.isAvailable) {
      debugPrint('Shorebird not available, returning false');
      return false;
    }

    try {
      debugPrint('Starting update check...');
      final currentPatch = await _updater.readCurrentPatch();
      debugPrint('Current patch before check: ${currentPatch?.number ?? 'None'}');

      final status = await _updater.checkForUpdate();
      debugPrint('Update status from Shorebird: $status');

      final isOutdated = status == UpdateStatus.outdated;
      debugPrint('Is outdated result: $isOutdated');
      return isOutdated;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    }
  }

  /// Performs the update with internal retries. Returns (success: true, errorMessage: null) on success,
  /// or (success: false, errorMessage: message) when download/install fails after retries.
  static Future<UpdateResult> performUpdate({
    int maxRetries = 3,
    void Function(int attempt, int maxRetries, String? lastError)? onRetry,
  }) async {
    if (!_updater.isAvailable) {
      return (success: false, errorMessage: 'Updates are not available in this build.');
    }

    // First check if update is already downloaded and ready to install
    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.restartRequired) {
        debugPrint('Update is already ready to install (restartRequired)');
        return (success: true, errorMessage: null);
      }
    } catch (e) {
      debugPrint('Error checking status before update: $e');
    }

    int attempt = 0;
    while (attempt < maxRetries) {
      String? lastErrorMessage;
      try {
        debugPrint('Update attempt ${attempt + 1} starting...');
        await _updater.update();
        debugPrint('Update completed successfully on attempt ${attempt + 1}');
        return (success: true, errorMessage: null);
      } on UpdateException catch (e) {
        attempt++;
        lastErrorMessage = e.message;
        debugPrint('Update attempt $attempt failed: ${e.message} (reason: ${e.reason})');
        
        if (e.reason == UpdateFailureReason.noUpdate) {
          return (success: true, errorMessage: null);
        }

        if (attempt >= maxRetries) {
          String message = e.message;
          switch (e.reason) {
            case UpdateFailureReason.downloadFailed:
              message = 'Download failed after $maxRetries attempts. Check your connection.';
              break;
            case UpdateFailureReason.installFailed:
              message = 'Install failed after $maxRetries attempts. Please try again or restart.';
              break;
            default:
              message = e.message.isNotEmpty ? e.message : 'Update failed. Please try again.';
          }
          return (success: false, errorMessage: message);
        }
      } catch (e) {
        attempt++;
        lastErrorMessage = e.toString();
        debugPrint('Error performing update on attempt $attempt: $e');
        if (attempt >= maxRetries) {
          return (
            success: false,
            errorMessage: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
          );
        }
      }

      if (onRetry != null) {
        onRetry(attempt, maxRetries, lastErrorMessage);
      }
      
      // Wait before retrying (exponential backoff: 2s, 4s...)
      await Future.delayed(Duration(seconds: attempt * 2));
    }
    
    return (success: false, errorMessage: 'Update failed after $maxRetries attempts.');
  }

  static Future<void> restartApp() async {
    // Add a small delay to ensure any pending file operations (like Shorebird's update)
    // are finalized before the process is killed and restarted.
    await Future.delayed(const Duration(milliseconds: 500));
    await Restart.restartApp();
  }

  static Future<Patch?> getCurrentPatch() async {
    if (!_updater.isAvailable) return null;

    try {
      return await _updater.readCurrentPatch();
    } catch (e) {
      debugPrint('Error reading current patch: $e');
      return null;
    }
  }

  static bool get isShorebirdAvailable => _updater.isAvailable;
}

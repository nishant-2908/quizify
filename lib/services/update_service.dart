import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

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

  /// Performs the update. Returns (success: true, errorMessage: null) on success,
  /// or (success: false, errorMessage: message) when download/install fails.
  static Future<UpdateResult> performUpdate() async {
    if (!_updater.isAvailable) {
      return (success: false, errorMessage: 'Updates are not available in this build.');
    }

    try {
      await _updater.update();
      debugPrint('Update completed successfully');
      return (success: true, errorMessage: null);
    } on UpdateException catch (e) {
      debugPrint('Update failed: ${e.message} (reason: ${e.reason})');
      String message = e.message;
      switch (e.reason) {
        case UpdateFailureReason.downloadFailed:
          message = 'Download failed. Check your connection and try again.';
          break;
        case UpdateFailureReason.installFailed:
          message = 'Install failed. Please try again or restart the app.';
          break;
        case UpdateFailureReason.noUpdate:
          message = 'No update is available.';
          break;
        case UpdateFailureReason.unknown:
          message = e.message.isNotEmpty ? e.message : 'Update failed. Please try again.';
          break;
      }
      return (success: false, errorMessage: message);
    } catch (e) {
      debugPrint('Error performing update: $e');
      return (
        success: false,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      );
    }
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

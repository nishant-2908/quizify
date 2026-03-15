import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  bool _isUpdating = false;
  bool _updateComplete = false;
  int _countdown = 5;
  String? _errorMessage;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String? _retryMessage;

  Future<void> _performUpdate() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
      _retryMessage = null;
    });

    _progressController.reset();
    _progressController.animateTo(0.9);

    final result = await UpdateService.performUpdate(
      onRetry: (attempt, max, error) {
        if (mounted) {
          setState(() {
            _retryMessage = 'Retrying... Attempt $attempt of $max\n$error';
          });
        }
      },
    );

    if (!mounted) return;

    if (result.success) {
      await _progressController.animateTo(1.0, duration: const Duration(milliseconds: 500));
      setState(() {
        _updateComplete = true;
        _isUpdating = false;
        _errorMessage = null;
        _retryMessage = null;
      });
      _startCountdown();
    } else {
      _progressController.stop();
      setState(() {
        _errorMessage = result.errorMessage ?? 'Update failed. Please try again later.';
        _isUpdating = false;
        _retryMessage = null;
      });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        _restartApp();
        return false;
      }
      return true;
    });
  }

  Future<void> _restartApp() async {
    await UpdateService.restartApp();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _isUpdating ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isUpdating ? _pulseAnimation.value : 1.0,
                    child: Icon(
                      _updateComplete 
                        ? Icons.check_circle 
                        : _isUpdating 
                          ? Icons.system_update 
                          : Icons.new_releases,
                      size: 48,
                      color: _updateComplete 
                        ? theme.colorScheme.primary
                        : _isUpdating
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Text(
              _updateComplete 
                ? 'Update Ready!'
                : _isUpdating 
                  ? 'Updating...'
                  : 'Update Available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              _updateComplete 
                ? 'The update has been downloaded successfully. App will restart automatically in $_countdown seconds...'
                : _isUpdating 
                  ? 'Downloading the latest update. This may take a few moments...'
                  : 'A new version of Quizify is available with improvements and bug fixes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            if (_retryMessage != null && _isUpdating) ...[
              const SizedBox(height: 12),
              Text(
                _retryMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can tap Retry to try again, or check for updates again later.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            
            if (_isUpdating) ...[
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            if (_updateComplete) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _restartApp,
                      child: const Text('Restart Now'),
                    ),
                  ),
                ],
              ),
            ] else if (_isUpdating) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_errorMessage != null ? 'Close' : 'Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _performUpdate,
                      icon: Icon(_errorMessage != null ? Icons.refresh : Icons.download),
                      label: Text(_errorMessage != null ? 'Retry' : 'Update'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

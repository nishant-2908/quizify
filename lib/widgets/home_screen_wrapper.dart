import 'package:flutter/material.dart';
import 'package:quizify/screens/home_screen.dart';
import 'package:quizify/services/update_service.dart';
import 'package:quizify/widgets/update_dialog.dart';

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    if (_updateChecked) return;

    // Wait for app and network to be ready so the update check is reliable
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    var hasUpdate = await UpdateService.checkForUpdates();
    // If no update, retry once after a short delay (e.g. patch CDN not ready yet)
    if (!hasUpdate) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      hasUpdate = await UpdateService.checkForUpdates();
    }

    _updateChecked = true;

    if (hasUpdate && mounted) {
      _showUpdateDialog();
    }
  }

  Future<void> _showUpdateDialog() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

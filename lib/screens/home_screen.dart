import 'package:flutter/material.dart';

import '../services/stats_service.dart';
import '../services/update_service.dart';
import '../utils/format.dart';
import '../widgets/update_dialog.dart';
import 'analysis_list_screen.dart';
import 'create_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OverallStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await getOverallStats();
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _checkForUpdatesManually() async {
    if (!UpdateService.isShorebirdAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updates are only available in Shorebird builds.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Get current patch info first
    final currentPatch = await UpdateService.getCurrentPatch();
    
    final hasUpdate = await UpdateService.checkForUpdates();
    
    if (hasUpdate && mounted) {
      final shouldRestart = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UpdateDialog(),
      );

      if (shouldRestart == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please manually restart the app to apply updates.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current patch: ${currentPatch?.number ?? 'None'} - You are using the latest version!'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final started = await Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => const CreateSessionScreen()));
          if (started == true) _loadStats();
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                toolbarHeight: 80, // Increased height for airy feel
                title: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    'Quizify',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.outline, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_stats == null)
                      const Center(
                        child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                      )
                    else
                      Card(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        child: Column(
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatTile(
                                      title: 'Accuracy',
                                      value: '${_stats!.overallAccuracy.toStringAsFixed(1)}%',
                                      icon: Icons.gps_fixed_outlined,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  VerticalDivider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), width: 1),
                                  Expanded(
                                    child: _StatTile(
                                      title: 'Questions',
                                      value: '${_stats!.attemptedQuestions}',
                                      icon: Icons.quiz_outlined,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatTile(
                                      title: 'Avg Time',
                                      value: formatDurationSeconds(_stats!.averageTimePerQuestionSeconds),
                                      icon: Icons.schedule_outlined,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                  ),
                                  VerticalDivider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), width: 1),
                                  Expanded(
                                    child: _StatTile(
                                      title: 'Total',
                                      value: '${_stats!.totalQuestions}',
                                      icon: Icons.summarize_outlined,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalysisListScreen()));
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('View Detailed Analysis'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _checkForUpdatesManually,
                      icon: const Icon(Icons.system_update),
                      label: const Text('Check for Updates'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

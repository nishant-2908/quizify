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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: Text(
                  'Quizify',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        final started = await Navigator.of(
                          context,
                        ).push<bool>(MaterialPageRoute(builder: (_) => const CreateSessionScreen()));
                        if (started == true) _loadStats();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create New Session'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Accuracy',
                                  value: '${_stats!.overallAccuracy.toStringAsFixed(1)}%',
                                  icon: Icons.gps_fixed_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Questions',
                                  value: '${_stats!.attemptedQuestions}',
                                  icon: Icons.quiz_outlined,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Avg Time',
                                  value: formatDurationSeconds(_stats!.averageTimePerQuestionSeconds),
                                  icon: Icons.schedule_outlined,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Total',
                                  value: '${_stats!.totalQuestions}',
                                  icon: Icons.summarize_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

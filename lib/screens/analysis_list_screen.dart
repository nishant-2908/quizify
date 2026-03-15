import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../models/subject.dart';
import '../services/database.dart';
import '../services/stats_service.dart';
import 'session_analysis_screen.dart';

class AnalysisListScreen extends StatefulWidget {
  const AnalysisListScreen({super.key});

  @override
  State<AnalysisListScreen> createState() => _AnalysisListScreenState();
}

class _AnalysisListScreenState extends State<AnalysisListScreen> {
  List<Session> _sessions = [];
  List<Subject> _subjects = [];
  List<SessionStats> _sessionStats = [];
  int? _filterSubjectId;
  String _filterSource = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final subjects = await AppDatabase.getAllSubjects();
    final sessions = await AppDatabase.getSessionsFiltered(
      subjectId: _filterSubjectId,
      source: _filterSource.isEmpty ? null : _filterSource,
    );

    // Calculate stats for each session
    final sessionStats = <SessionStats>[];
    for (final session in sessions) {
      final stats = await getSessionStats(session);
      sessionStats.add(stats);
    }

    if (mounted) {
      setState(() {
        _subjects = subjects;
        _sessions = sessions;
        _sessionStats = sessionStats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'Session History',
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
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: const Text('All Subjects'),
                            selected: _filterSubjectId == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _filterSubjectId = null);
                                _load();
                              }
                            },
                            selectedColor: Theme.of(context).colorScheme.primary,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                            labelStyle: TextStyle(
                              color: _filterSubjectId == null ? Theme.of(context).colorScheme.onPrimary : null,
                            ),
                          ),
                        ),
                        ..._subjects.map((s) {
                          final isSelected = _filterSubjectId == s.id;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(s.displayName),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _filterSubjectId = selected ? s.id : null);
                                _load();
                              },
                              selectedColor: Theme.of(context).colorScheme.primary,
                              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                              labelStyle: TextStyle(
                                color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                    )
                  else if (_sessions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.history_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No sessions found',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or create a new session',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_sessions.length, (i) {
                      final s = _sessions[i];
                      final stats = _sessionStats[i];
                      Subject? sub;
                      for (final x in _subjects) {
                        if (x.id == s.subjectId) {
                          sub = x;
                          break;
                        }
                      }
                      return _SessionCard(
                        session: s,
                        stats: stats,
                        subjectDisplayName: sub?.displayName,
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          final session = await AppDatabase.getSessionById(s.id);
                          if (session == null) return;
                          navigator.push(MaterialPageRoute(builder: (_) => SessionAnalysisScreen(session: session)));
                        },
                      );
                    }),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final SessionStats stats;
  final String? subjectDisplayName;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.stats, this.subjectDisplayName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    try {
      dt = DateTime.parse(session.datetime);
    } catch (_) {}
    final dateStr = dt != null ? DateFormat.yMMMd().add_Hm().format(dt) : session.datetime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              subjectDisplayName?.split(' · ').first ?? 'Session',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${stats.totalMarks} marks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: stats.totalMarks >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subjectDisplayName?.contains(' · ') == true)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subjectDisplayName!.split(' · ').last,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.source_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        session.source,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

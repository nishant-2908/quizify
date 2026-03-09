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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.filter_list_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Filters',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int?>(
                            initialValue: _filterSubjectId,
                            decoration: InputDecoration(
                              hintText: 'All subjects',
                              prefixIcon: const Icon(Icons.book_outlined),
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All subjects')),
                              ..._subjects.map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      s.displayName, 
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _filterSubjectId = v);
                              _load();
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Filter by source...',
                              prefixIcon: const Icon(Icons.source_outlined),
                              suffixIcon: _filterSource.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        setState(() => _filterSource = '');
                                        _load();
                                      },
                                      icon: const Icon(Icons.clear_outlined),
                                    )
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.words,
                            controller: TextEditingController(text: _filterSource)
                              ..selection = TextSelection.fromPosition(TextPosition(offset: _filterSource.length)),
                            onSubmitted: (v) {
                              setState(() => _filterSource = v.trim());
                              _load();
                            },
                          ),
                        ],
                      ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subjectDisplayName?.split(' · ').first ?? 'Session',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                ],
              ),
              const SizedBox(height: 8),
              if (subjectDisplayName?.contains(' · ') == true)
                Text(
                  subjectDisplayName!.split(' · ').last,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.source_outlined, size: 16, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      session.source,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 16, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 16,
                    color: stats.totalMarks >= 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.totalMarks} marks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: stats.totalMarks >= 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

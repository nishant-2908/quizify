import 'package:flutter/material.dart';

import '../models/question.dart' as question_model;
import '../models/session_state.dart';
import '../models/session.dart';
import '../models/subject.dart';
import '../services/database.dart';
import '../services/stats_service.dart';
import '../utils/decimal_input_formatter.dart';
import '../utils/format.dart';
import 'question_detail_screen.dart';

class SessionAnalysisScreen extends StatefulWidget {
  final Session session;

  const SessionAnalysisScreen({super.key, required this.session});

  @override
  State<SessionAnalysisScreen> createState() => _SessionAnalysisScreenState();
}

class _SessionAnalysisScreenState extends State<SessionAnalysisScreen> {
  SessionStats? _stats;
  List<question_model.QuestionRecord>? _questions;
  Subject? _subject;
  bool _loading = true;
  bool _editingMode = false;
  final List<String?> _editingAnswers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await getSessionStats(widget.session);
    final questions = await AppDatabase.getQuestionsBySessionId(widget.session.id);
    final subject = await AppDatabase.getSubjectById(widget.session.subjectId);
    if (mounted) {
      setState(() {
        _stats = stats;
        _questions = questions;
        _subject = subject;
        _loading = false;
        _editingAnswers.clear();
        _editingAnswers.addAll(questions.map((q) => q.correctOption));
      });
    }
  }

  bool get _hasIncompleteQuestions {
    return _questions?.any((q) => q.correctOption == null || q.correctOption!.isEmpty) ?? false;
  }

  Set<String> _parseOptions(String? s) {
    if (s == null || s.trim().isEmpty) return {};
    return s.split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toSet();
  }

  void _toggleEditingMcqOption(int index, String opt) {
    final current = _parseOptions(_editingAnswers[index]);
    final qType = _questions![index].questionType;
    if (qType == kQuestionTypeSingleChoice) {
      setState(() => _editingAnswers[index] = current.contains(opt) ? null : opt);
      return;
    }
    if (current.contains(opt)) {
      current.remove(opt);
    } else {
      current.add(opt);
    }
    final list = current.toList()..sort();
    setState(() => _editingAnswers[index] = list.isEmpty ? null : list.join(','));
  }

  Widget _buildMcqEditOptions(BuildContext context, int index) {
    final selectedSet = _parseOptions(_editingAnswers[index]);
    final qType = _questions![index].questionType;
    return Row(
      children: ['A', 'B', 'C', 'D'].map((opt) {
        final selected = selectedSet.contains(opt);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FilledButton.tonal(
              onPressed: () => _toggleEditingMcqOption(index, opt),
              style: FilledButton.styleFrom(
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                foregroundColor: selected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected
                        ? (qType == kQuestionTypeSingleChoice ? Icons.radio_button_checked : Icons.check_box)
                        : (qType == kQuestionTypeSingleChoice ? Icons.radio_button_unchecked : Icons.check_box_outline_blank),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opt,
                    style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _editingMode = !_editingMode;
    });
  }

  Future<void> _saveUpdatedAnswers() async {
    for (int i = 0; i < _questions!.length; i++) {
      final question = _questions![i];
      if (question.correctOption != _editingAnswers[i]) {
        await AppDatabase.updateQuestion(
          question_model.QuestionRecord(
            id: question.id,
            selectedOption: question.selectedOption,
            correctOption: _editingAnswers[i],
            timeSpent: question.timeSpent,
            sessionId: question.sessionId,
            questionNumber: question.questionNumber,
            questionType: question.questionType,
          ),
        );
      }
    }

    await _load(); // Reload to get updated stats
    setState(() {
      _editingMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answers updated successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_outlined),
                    ),
                    const Spacer(),
                    Text(
                      'Session Analysis',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }
    final s = _stats!;
    final questions = _questions!;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'Session Analysis',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              centerTitle: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              actions: [
                if (_hasIncompleteQuestions && !_editingMode)
                  TextButton.icon(
                    onPressed: _toggleEditMode,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Complete'),
                  ),
                if (_editingMode)
                  TextButton.icon(
                    onPressed: _saveUpdatedAnswers,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_subject != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.book_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _subject!.displayName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.source_outlined, size: 16, color: Theme.of(context).colorScheme.outline),
                                const SizedBox(width: 4),
                                Text(
                                  'Source: ${widget.session.source}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Accuracy',
                          value: '${s.accuracy.toStringAsFixed(1)}%',
                          icon: Icons.gps_fixed_outlined,
                          color: _getAccuracyColor(s.accuracy),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Marks',
                          value: '${s.totalMarks}',
                          icon: Icons.workspace_premium,
                          color: s.totalMarks >= 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Time',
                          value: formatDurationSeconds(s.totalTimeSpent),
                          icon: Icons.schedule_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Avg Time',
                          value: formatDurationSeconds(s.averageTimePerQuestion.round()),
                          icon: Icons.timer_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Questions',
                          value: '${s.questionsAttempted}/${s.totalQuestions}',
                          icon: Icons.quiz_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MarkingSchemeCard(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Breakdown',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _BreakdownItem(label: 'Correct', value: '${s.correct}', color: Colors.green),
                              ),
                              Expanded(
                                child: _BreakdownItem(label: 'Incorrect', value: '${s.incorrect}', color: Colors.red),
                              ),
                              Expanded(
                                child: _BreakdownItem(label: 'Skipped', value: '${s.skipped}', color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.list_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Question Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(questions.length, (i) {
                    final q = questions[i];
                    final isCorrect = q.isCorrect;
                    final skipped = q.wasSkipped;
                    final isIncomplete = q.correctOption == null || q.correctOption!.isEmpty;

                    if (_editingMode && isIncomplete) {
                      final isNumerical = q.questionType == kQuestionTypeNumerical;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                      'Q${q.questionNumber}',
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Set correct answer',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isNumerical)
                                TextFormField(
                                  key: ValueKey('num_edit_$i'),
                                  initialValue: _editingAnswers[i] ?? '',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                                  inputFormatters: [
                                    DecimalTextInputFormatter(decimalRange: 2),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Correct numerical value',
                                    prefixIcon: Icon(Icons.numbers_outlined),
                                  ),
                                  onChanged: (value) => setState(() => _editingAnswers[i] = value.trim().isEmpty ? null : value.trim()),
                                )
                              else
                                _buildMcqEditOptions(context, i),
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getQuestionStatusColor(skipped, isCorrect, isIncomplete),
                          child: Text(
                            '${q.questionNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        title: Text(
                          'Question ${q.questionNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncomplete
                                  ? 'Incomplete - No correct answer set'
                                  : skipped
                                  ? 'Skipped'
                                  : 'Marked: ${q.selectedOption} | Correct: ${q.correctOption}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Time: ${formatDurationSeconds(q.timeSpent)}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => QuestionDetailScreen(question: q)));
                        },
                      ),
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

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getQuestionStatusColor(bool skipped, bool isCorrect, bool isIncomplete) {
    if (skipped) return Colors.grey;
    if (isIncomplete) return Colors.orange;
    return isCorrect ? Colors.green : Colors.red;
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

class _MarkingSchemeCard extends StatelessWidget {
  const _MarkingSchemeCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );
    return Card(
      shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Marking scheme',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Single: +4 / -1', style: textStyle),
            const SizedBox(height: 2),
            Text('Multi: +4, +1, -2', style: textStyle),
            const SizedBox(height: 2),
            Text('Num: +4 / -1', style: textStyle),
          ],
        ),
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BreakdownItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Center(
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

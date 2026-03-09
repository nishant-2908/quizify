import 'package:flutter/material.dart';

import '../models/session_state.dart';
import '../models/session.dart' as session_model;
import '../models/question.dart' as question_model;
import '../services/database.dart';
import '../utils/decimal_input_formatter.dart';
import 'session_analysis_screen.dart';
import 'home_screen.dart';

class AnswerKeyScreen extends StatefulWidget {
  final PendingSession pending;

  const AnswerKeyScreen({super.key, required this.pending});

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  final List<String?> _correctAnswers = []; // index = question index
  late List<TextEditingController> _numericalControllers;

  @override
  void initState() {
    super.initState();
    _correctAnswers.addAll(
      List.filled(widget.pending.questions.length, null),
    );
    _numericalControllers = List.generate(
      widget.pending.questions.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _numericalControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Set<String> _parseOptions(String? s) {
    if (s == null || s.trim().isEmpty) return {};
    return s.split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toSet();
  }

  void _toggleCorrectOption(int index, String opt) {
    final current = _parseOptions(_correctAnswers[index]);
    final qType = widget.pending.questions[index].questionType;
    if (qType == kQuestionTypeSingleChoice) {
      setState(() => _correctAnswers[index] = current.contains(opt) ? null : opt);
      return;
    }
    if (current.contains(opt)) {
      current.remove(opt);
    } else {
      current.add(opt);
    }
    final list = current.toList()..sort();
    setState(() => _correctAnswers[index] = list.isEmpty ? null : list.join(','));
  }

  Widget _buildMcqCorrectOptions(
    BuildContext context,
    int index,
    String? correct,
    String? userAnswer,
  ) {
    final correctSet = _parseOptions(correct);
    final userSet = _parseOptions(userAnswer);
    final qType = widget.pending.questions[index].questionType;
    return Row(
      children: ['A', 'B', 'C', 'D'].map((opt) {
        final isSelected = correctSet.contains(opt);
        final isUserAnswer = userSet.contains(opt);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FilledButton.tonal(
              onPressed: () => _toggleCorrectOption(index, opt),
              style: FilledButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : isUserAnswer
                        ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5)
                        : null,
                foregroundColor: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected
                        ? (qType == kQuestionTypeSingleChoice ? Icons.radio_button_checked : Icons.check_box)
                        : (qType == kQuestionTypeSingleChoice ? Icons.radio_button_unchecked : Icons.check_box_outline_blank),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opt,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    await _saveSession(navigateToAnalysis: true);
  }

  Future<void> _saveSession({bool navigateToAnalysis = false}) async {
    for (int i = 0; i < widget.pending.questions.length; i++) {
      if (widget.pending.questions[i].questionType == kQuestionTypeNumerical) {
        final t = _numericalControllers[i].text.trim();
        _correctAnswers[i] = t.isEmpty ? null : t;
      }
    }
    final session = session_model.Session(
      id: 0,
      datetime: widget.pending.startedAt,
      subjectId: widget.pending.subjectId,
      source: widget.pending.source,
      totalTimeSpent: widget.pending.totalTimeSpentSeconds,
    );
    final sessionId = await AppDatabase.insertSession(session);
    
    for (int i = 0; i < widget.pending.questions.length; i++) {
      final q = widget.pending.questions[i];
      await AppDatabase.insertQuestion(
        question_model.QuestionRecord(
          id: 0,
          selectedOption: q.selectedOption,
          correctOption: _correctAnswers[i],
          timeSpent: q.timeSpentSeconds,
          sessionId: sessionId,
          questionNumber: i + 1 + widget.pending.questionNumberOffset,
          questionType: q.questionType,
        ),
      );
    }
    
    if (navigateToAnalysis) {
      final savedSession = await AppDatabase.getSessionById(sessionId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionAnalysisScreen(session: savedSession!),
        ),
      );
    }
  }

  Future<void> _savePartialSession() async {
    await _saveSession(navigateToAnalysis: false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Answer Key?'),
            content: const Text(
              'Answer key submission won\'t continue. Your progress will be saved with current answers. Unanswered questions will remain blank.',
              overflow: TextOverflow.clip,
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        
        if (shouldExit == true) {
          await _savePartialSession();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: Text(
                  'Answer Key',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.key_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Set correct answer for each question.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(widget.pending.questions.length, (i) {
                      final correct = _correctAnswers[i];
                      final userAnswer = widget.pending.questions[i].selectedOption;
                      final isNumerical = widget.pending.questions[i].questionType == kQuestionTypeNumerical;
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
                                      'Q${i + 1 + widget.pending.questionNumberOffset}',
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (userAnswer != null && userAnswer.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'You: $userAnswer',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (correct == null || correct.isEmpty)
                                    Icon(
                                      Icons.help_outline,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.outline,
                                    )
                                  else
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isNumerical)
                                TextField(
                                  controller: _numericalControllers[i],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                                  inputFormatters: [
                                    DecimalTextInputFormatter(decimalRange: 2),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Correct numerical answer',
                                    hintText: 'Enter value',
                                    prefixIcon: Icon(Icons.numbers_outlined),
                                  ),
                                  onChanged: (value) => setState(() => _correctAnswers[i] = value.trim().isEmpty ? null : value.trim()),
                                )
                              else
                                _buildMcqCorrectOptions(context, i, correct, userAnswer),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Submit & See Analysis'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 0),
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

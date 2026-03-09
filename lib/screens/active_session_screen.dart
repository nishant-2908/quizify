import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/session_state.dart';
import '../utils/decimal_input_formatter.dart';
import '../utils/format.dart';
import 'answer_key_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final PendingSession pending;

  const ActiveSessionScreen({super.key, required this.pending});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> with WidgetsBindingObserver {
  late List<QuestionState> _questions;
  late int _currentIndex;
  int _sessionElapsedSeconds = 0;
  int _questionNumberOffset = 0;
  String _defaultQuestionTypeForNew = kQuestionTypeMultipleChoice;
  Timer? _sessionTimer;
  Timer? _questionTimer;
  final TextEditingController _numericalAnswerController = TextEditingController();
  int _lastNumericalIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questions = List.from(widget.pending.questions
        .map((q) => QuestionState(
              selectedOption: q.selectedOption,
              timeSpentSeconds: q.timeSpentSeconds,
              questionType: q.questionType,
            )));
    _currentIndex = 0;
    _questionNumberOffset = widget.pending.questionNumberOffset;
    _startSessionTimers();
    WakelockPlus.enable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      WakelockPlus.disable();
    }
  }

  void _startSessionTimers() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _sessionElapsedSeconds++);
      }
    });
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _currentIndex < _questions.length) {
        setState(() => _questions[_currentIndex].timeSpentSeconds++);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _sessionTimer?.cancel();
    _questionTimer?.cancel();
    _numericalAnswerController.dispose();
    super.dispose();
  }

  void _toggleOption(String option) {
    if (_currentIndex >= _questions.length) return;
    setState(() {
      final q = _questions[_currentIndex];
      if (q.questionType == kQuestionTypeSingleChoice) {
        q.selectedOption = q.selectedOption == option ? null : option;
        return;
      }
      final current = _parseSelectedOptions(q.selectedOption);
      if (current.contains(option)) {
        current.remove(option);
      } else {
        current.add(option);
      }
      final list = current.toList()..sort();
      q.selectedOption = list.isEmpty ? null : list.join(',');
    });
  }

  Set<String> _parseSelectedOptions(String? s) {
    if (s == null || s.trim().isEmpty) return {};
    return s.split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toSet();
  }


  void _goNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _syncNumericalController();
      });
    } else {
      // Only add next question when user explicitly clicks Next
      _questions.add(QuestionState(questionType: _defaultQuestionTypeForNew));
      setState(() {
        _currentIndex = _questions.length - 1;
        _syncNumericalController();
      });
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _syncNumericalController();
      });
    }
  }

  void _syncNumericalController() {
    if (_currentIndex >= 0 &&
        _currentIndex < _questions.length &&
        _questions[_currentIndex].questionType == kQuestionTypeNumerical) {
      _numericalAnswerController.text =
          _questions[_currentIndex].selectedOption ?? '';
      _numericalAnswerController.selection = TextSelection.collapsed(
        offset: _numericalAnswerController.text.length,
      );
    }
    _lastNumericalIndex = _currentIndex;
  }


  void _clearResponse() {
    if (_currentIndex >= _questions.length) return;
    setState(() {
      _questions[_currentIndex].selectedOption = null;
      if (_questions[_currentIndex].questionType == kQuestionTypeNumerical) {
        _numericalAnswerController.clear();
      }
    });
  }

  void _showEditQuestion() async {
    if (_currentIndex >= _questions.length) return;

    final currentDisplayNumber = _currentIndex + 1 + _questionNumberOffset;
    final currentType = _questions[_currentIndex].questionType;

    final numberController = TextEditingController(text: '$currentDisplayNumber');
    String selectedType = currentType;

    final result = await showDialog<({int number, String type})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Question number',
                    hintText: 'Enter question number',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Question type',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: kQuestionTypeSingleChoice,
                      groupValue: selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                      title: const Text('Single choice'),
                      secondary: const Icon(Icons.radio_button_checked_outlined, size: 18),
                    ),
                    RadioListTile<String>(
                      value: kQuestionTypeMultipleChoice,
                      groupValue: selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                      title: const Text('Multiple correct'),
                      secondary: const Icon(Icons.checklist_outlined, size: 18),
                    ),
                    RadioListTile<String>(
                      value: kQuestionTypeNumerical,
                      groupValue: selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                      title: const Text('Numerical'),
                      secondary: const Icon(Icons.numbers_outlined, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final number = int.tryParse(numberController.text);
                if (number != null && number > 0) {
                  Navigator.of(context).pop((number: number, type: selectedType));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid question number')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final newNumber = result.number;
    final newType = result.type;
    final numberChanged = newNumber != currentDisplayNumber;
    final typeChanged = newType != currentType;

    if (numberChanged) {
      final offsetChange = newNumber - currentDisplayNumber;
      final shouldApplyNumber = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Apply to following questions?'),
          content: Text(
            'Do you want to change the question number for all following questions too?\n\n'
            'Current Q$currentDisplayNumber will become Q$newNumber. '
            'All following questions will be shifted by ${offsetChange > 0 ? '+' : ''}$offsetChange.',
            overflow: TextOverflow.ellipsis,
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (shouldApplyNumber == true) {
        setState(() => _questionNumberOffset += offsetChange);
      }
    }

    if (typeChanged) {
      setState(() => _questions[_currentIndex].questionType = newType);
      final shouldApplyType = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Apply to following questions?'),
          content: Text(
            'Do you want to set the question type to "${newType == kQuestionTypeNumerical ? 'Numerical' : newType == kQuestionTypeSingleChoice ? 'Single choice' : 'Multiple correct'}" for all following questions too?',
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (shouldApplyType == true) {
        setState(() {
          _defaultQuestionTypeForNew = newType;
          for (int i = _currentIndex + 1; i < _questions.length; i++) {
            _questions[i].questionType = newType;
          }
        });
      }
    }
  }

  Widget _buildNumericalInput(BuildContext context, QuestionState? q) {
    if (q != null && _currentIndex != _lastNumericalIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex < _questions.length &&
            _questions[_currentIndex].questionType == kQuestionTypeNumerical) {
          _numericalAnswerController.text =
              _questions[_currentIndex].selectedOption ?? '';
          _numericalAnswerController.selection = TextSelection.collapsed(
            offset: _numericalAnswerController.text.length,
          );
          _lastNumericalIndex = _currentIndex;
        }
      });
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: _numericalAnswerController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
          inputFormatters: [
            DecimalTextInputFormatter(decimalRange: 2),
          ],
          decoration: InputDecoration(
            labelText: 'Your answer',
            hintText: 'Enter numerical value',
            prefixIcon: const Icon(Icons.numbers_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            if (_currentIndex < _questions.length) {
              // Ensure we never store a negative value even if pasted.
              final sanitized = value.replaceAll('-', '').trim();
              setState(() {
                _questions[_currentIndex].selectedOption =
                    sanitized.isEmpty ? null : sanitized;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(BuildContext context, QuestionState? q) {
    final selectedSet = _parseSelectedOptions(q?.selectedOption);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['A', 'B', 'C', 'D'].map((opt) {
        final selected = selectedSet.contains(opt);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _toggleOption(opt),
              icon: selected
                  ? Icon(
                      q?.questionType == kQuestionTypeSingleChoice ? Icons.radio_button_checked : Icons.check_circle,
                      size: 20,
                    )
                  : Icon(
                      q?.questionType == kQuestionTypeSingleChoice
                          ? Icons.radio_button_unchecked
                          : Icons.check_box_outline_blank,
                      size: 20,
                    ),
              label: Text(
                opt,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
                    : null,
                foregroundColor: selected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _endSession() async {
    _sessionTimer?.cancel();
    _questionTimer?.cancel();
    List<QuestionState> list = List.from(_questions);
    
    // Remove the last auto-added empty question if it exists
    if (list.isNotEmpty) {
      final last = list.last;
      if (last.selectedOption == null || last.selectedOption!.isEmpty) {
        list.removeLast();
      }
    }
    
    if (list.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final pending = PendingSession(
      subjectId: widget.pending.subjectId,
      source: widget.pending.source,
      startedAt: widget.pending.startedAt,
      questions: list,
      questionNumberOffset: _questionNumberOffset,
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AnswerKeyScreen(pending: pending),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentIndex < _questions.length ? _questions[_currentIndex] : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('End Session?'),
            content: const Text('Are you sure you want to exit? Your current progress will be saved.'),
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
          _endSession();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header with timer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final shouldExit = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('End Session?'),
                                content: const Text(
                                  'Are you sure you want to exit? Your current progress will be saved.',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => navigator.pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => navigator.pop(true),
                                    child: const Text('Exit'),
                                  ),
                                ],
                              ),
                            );
                            if (shouldExit == true) {
                              _endSession();
                            }
                          },
                          icon: const Icon(Icons.close_outlined),
                        ),
                        const Spacer(),
                        Text(
                          'Session Timer',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            formatDurationSeconds(_sessionElapsedSeconds),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Question info
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Question ${_currentIndex + 1 + _questionNumberOffset}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton.outlined(
                          onPressed: _showEditQuestion,
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit question number & type',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Current: ${q != null ? formatDurationSeconds(q.timeSpentSeconds) : "00:00"}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Answer options (multiple choice or numerical)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Expanded(
                        child: q?.questionType == kQuestionTypeNumerical
                            ? _buildNumericalInput(context, q)
                            : _buildMultipleChoiceOptions(context, q),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Navigation controls
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _currentIndex > 0 ? _goPrevious : null,
                            child: const Icon(Icons.arrow_back_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearResponse,
                            child: const Text(
                              'Clear',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: _goNext,
                            child: const Icon(Icons.arrow_forward_outlined, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _endSession,
                        icon: const Icon(Icons.stop_circle_outlined, size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text('End Session', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/question.dart' as question_model;
import '../utils/format.dart';

class QuestionDetailScreen extends StatelessWidget {
  final question_model.QuestionRecord question;

  const QuestionDetailScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final correct = question.isCorrect;
    final partial = question.isPartiallyCorrect;
    final skipped = question.wasSkipped;

    Color getStatusColor(bool skipped, bool correct) {
      if (skipped) return Theme.of(context).colorScheme.outline;
      if (partial) return Theme.of(context).colorScheme.tertiary;
      return correct ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
    }

    Color getMarksColor(bool skipped, bool correct) {
      if (skipped) return Theme.of(context).colorScheme.outline;
      if (question.marks > 0) return Theme.of(context).colorScheme.primary;
      return correct ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
    }

    String getStatusText(bool skipped, bool correct) {
      if (skipped) return 'Skipped';
      if (partial) return 'Partially correct';
      return correct ? 'Correct' : 'Incorrect';
    }

    String getMarksText(bool skipped, bool correct) {
      if (skipped) return '0 marks';
      final m = question.marks;
      return m >= 0 ? '+$m marks' : '$m marks';
    }

    IconData getStatusIcon(bool skipped, bool correct) {
      if (skipped) return Icons.skip_next_outlined;
      if (partial) return Icons.check_circle_outline;
      return correct ? Icons.check_circle_outline : Icons.cancel_outlined;
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'Question ${question.questionNumber}',
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
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.schedule_outlined,
                            label: 'Time spent',
                            value: formatDurationSeconds(question.timeSpent),
                          ),
                          const Divider(),
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Your answer',
                            value: question.selectedOption ?? '— (skipped)',
                            isUserAnswer: true,
                          ),
                          const Divider(),
                          _DetailRow(
                            icon: Icons.check_circle_outline,
                            label: 'Correct answer',
                            value: question.correctOption ?? '—',
                            isCorrectAnswer: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            getStatusIcon(skipped, correct),
                            color: getStatusColor(skipped, correct),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            getStatusText(skipped, correct),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: getStatusColor(skipped, correct),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: getStatusColor(skipped, correct).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getStatusText(skipped, correct),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: getStatusColor(skipped, correct),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.calculate_outlined,
                            label: 'Marks for this question',
                            value: getMarksText(skipped, correct),
                            isMarksRow: true,
                            marksColor: getMarksColor(skipped, correct),
                          ),
                        ],
                      ),
                    ),
                  ),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isUserAnswer;
  final bool isCorrectAnswer;
  final bool isMarksRow;
  final Color? marksColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isUserAnswer = false,
    this.isCorrectAnswer = false,
    this.isMarksRow = false,
    this.marksColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isMarksRow
                ? (marksColor ?? Theme.of(context).colorScheme.outline)
                : isUserAnswer
                    ? Theme.of(context).colorScheme.primary
                    : isCorrectAnswer
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isUserAnswer || isCorrectAnswer || isMarksRow ? FontWeight.w600 : FontWeight.normal,
              color: isMarksRow
                  ? (marksColor ?? Theme.of(context).colorScheme.outline)
                  : isUserAnswer
                      ? Theme.of(context).colorScheme.primary
                      : isCorrectAnswer
                          ? Theme.of(context).colorScheme.primary
                          : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

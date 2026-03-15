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
      if (skipped) return Colors.grey;
      if (partial) return Colors.orange;
      return correct ? Colors.green : Colors.red;
    }

    Color getMarksColor(bool skipped, bool correct) {
      if (skipped) return Colors.grey;
      if (question.marks > 0) return Colors.green;
      return correct ? Colors.green : Colors.red;
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
      if (partial) return Icons.fact_check_outlined;
      return correct ? Icons.check_circle_outlined : Icons.cancel_outlined;
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'Question ${question.questionNumber}',
                style: Theme.of(context).textTheme.headlineMedium,
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
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.schedule_outlined,
                            label: 'Time spent',
                            value: formatDurationSeconds(question.timeSpent),
                          ),
                          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Your answer',
                            value: question.selectedOption ?? '— (skipped)',
                            isUserAnswer: true,
                          ),
                          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          _DetailRow(
                            icon: getStatusIcon(skipped, correct),
                            label: 'Status',
                            value: getStatusText(skipped, correct),
                            statusColor: getStatusColor(skipped, correct),
                          ),
                          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          _DetailRow(
                            icon: Icons.check_circle_outline,
                            label: 'Correct answer',
                            value: question.correctOption ?? '—',
                            isCorrectAnswer: true,
                            statusColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            getStatusIcon(skipped, correct),
                            color: getStatusColor(skipped, correct),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getStatusText(skipped, correct),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: getStatusColor(skipped, correct),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Performance status',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: getStatusColor(skipped, correct).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getMarksText(skipped, correct),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: getStatusColor(skipped, correct),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.calculate_outlined,
                            label: 'Marks for this question',
                            value: getMarksText(skipped, correct),
                            isMarksRow: true,
                            statusColor: getMarksColor(skipped, correct),
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
  final Color? statusColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isUserAnswer = false,
    this.isCorrectAnswer = false,
    this.isMarksRow = false,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: statusColor ??
                (isUserAnswer || isCorrectAnswer
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isUserAnswer || isCorrectAnswer || isMarksRow ? FontWeight.w600 : FontWeight.normal,
                    color: statusColor ??
                        (isUserAnswer || isCorrectAnswer
                            ? Theme.of(context).colorScheme.primary
                            : null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

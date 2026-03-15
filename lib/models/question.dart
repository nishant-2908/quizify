import 'session_state.dart';

/// Question in a session. timeSpent in seconds. selectedOption/correctOption: 'A'|'B'|'C'|'D' for MC, or numeric string for numerical; empty for skip.
class QuestionRecord {
  final int id;
  final String? selectedOption;
  final String? correctOption;
  final int timeSpent;
  final int sessionId;
  final int questionNumber;
  final String questionType; // kQuestionTypeSingleChoice | kQuestionTypeMultipleChoice | kQuestionTypeNumerical

  const QuestionRecord({
    required this.id,
    this.selectedOption,
    this.correctOption,
    required this.timeSpent,
    required this.sessionId,
    required this.questionNumber,
    String? questionType,
  }) : questionType = questionType ?? kQuestionTypeMultipleChoice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'selected_option': selectedOption,
      'correct_option': correctOption,
      'time_spent': timeSpent,
      'session_id': sessionId,
      'question_number': questionNumber,
      'question_type': questionType,
    };
  }

  factory QuestionRecord.fromMap(Map<String, dynamic> map) {
    return QuestionRecord(
      id: map['id'] as int,
      selectedOption: map['selected_option'] as String?,
      correctOption: map['correct_option'] as String?,
      timeSpent: map['time_spent'] as int,
      sessionId: map['session_id'] as int,
      questionNumber: map['question_number'] as int,
      questionType: map['question_type'] as String? ?? kQuestionTypeMultipleChoice,
    );
  }

  bool get wasSkipped => selectedOption == null || selectedOption!.isEmpty;
  bool get isNumerical => questionType == kQuestionTypeNumerical;
  bool get isSingleChoice => questionType == kQuestionTypeSingleChoice;
  bool get isMultipleCorrectChoice => questionType == kQuestionTypeMultipleChoice;

  bool get isCorrect {
    if (correctOption == null || selectedOption == null || selectedOption!.isEmpty) return false;
    if (isNumerical) {
      final a = num.tryParse(selectedOption!.trim());
      final b = num.tryParse(correctOption!.trim());
      if (a != null && b != null) return a == b;
      return selectedOption!.trim() == correctOption!.trim();
    }
    final correctSet = _parseOptions(correctOption!);
    final selectedSet = _parseOptions(selectedOption!);
    return correctSet.length == selectedSet.length && correctSet.every((o) => selectedSet.contains(o));
  }

  bool get isPartiallyCorrect {
    if (wasSkipped) return false;
    if (correctOption == null || correctOption!.isEmpty) return false;
    if (!isMultipleCorrectChoice) return false;

    final correctSet = _parseOptions(correctOption!);
    final selectedSet = _parseOptions(selectedOption ?? '');
    if (selectedSet.isEmpty) return false;
    final incorrectSelected = selectedSet.difference(correctSet);
    if (incorrectSelected.isNotEmpty) return false;
    if (selectedSet.length == correctSet.length && correctSet.every(selectedSet.contains)) return false;
    return true;
  }

  /// Marks for this question based on JEE Advanced pattern:
  /// - Numerical: +4 correct, -1 incorrect, 0 skipped.
  /// - Single choice: +4 correct, -1 incorrect, 0 skipped.
  /// - Multiple choice (one or more correct):
  ///   a) skipped -> 0
  ///   b) fully correct (selected == correct) -> +4
  ///   c) partially correct (selected ⊂ correct) -> +1 per selected option (max +3)
  ///   d) any wrong selected (selected \ correct != ∅) -> -2
  int get marks {
    if (wasSkipped) return 0;
    if (correctOption == null || correctOption!.isEmpty) return 0;

    if (isNumerical) {
      return isCorrect ? 4 : -1;
    }

    if (isSingleChoice) {
      return isCorrect ? 4 : -1;
    }

    // Multiple Correct logic
    final correctSet = _parseOptions(correctOption!);
    final selectedSet = _parseOptions(selectedOption!);
    if (selectedSet.isEmpty) return 0;

    final hasIncorrect = selectedSet.any((o) => !correctSet.contains(o));
    if (hasIncorrect) return -2;

    if (selectedSet.length == correctSet.length) return 4;

    // Partial marking: +1, +2, or +3 based on number of correct options selected
    return selectedSet.length;
  }

  static Set<String> _parseOptions(String s) {
    if (s.trim().isEmpty) return {};
    return s.split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toSet();
  }
}

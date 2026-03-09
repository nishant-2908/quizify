/// Question type:
/// - single_choice: single correct option (A/B/C/D)
/// - multiple_choice: multiple correct options (A/B/C/D)
/// - numerical: user enters a number
const String kQuestionTypeSingleChoice = 'single_choice';
const String kQuestionTypeMultipleChoice = 'multiple_choice';
const String kQuestionTypeNumerical = 'numerical';

/// In-memory state for one question during an active session.
class QuestionState {
  String? selectedOption; // A, B, C, D for MC; numeric string for numerical; null for skip
  int timeSpentSeconds;
  String questionType; // kQuestionTypeMultipleChoice | kQuestionTypeNumerical

  QuestionState({
    this.selectedOption,
    this.timeSpentSeconds = 0,
    String? questionType,
  }) : questionType = questionType ?? kQuestionTypeMultipleChoice;
}

/// Pending session: not saved until answer key is submitted. Used from active session -> answer key.
class PendingSession {
  final int subjectId;
  final String source;
  final String startedAt; // iso datetime
  final List<QuestionState> questions; // after "end session" the last unattempted one is removed
  int questionNumberOffset; // offset for question numbering (e.g., if offset is 47, Q1 displays as Q48)

  PendingSession({
    required this.subjectId,
    required this.source,
    required this.startedAt,
    required this.questions,
    this.questionNumberOffset = 0,
  });

  int get totalTimeSpentSeconds =>
      questions.fold(0, (sum, q) => sum + q.timeSpentSeconds);
}

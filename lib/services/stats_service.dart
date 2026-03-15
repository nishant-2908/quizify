import '../models/session.dart';
import 'database.dart';

class OverallStats {
  final double overallAccuracy; // 0..100
  final int averageTimePerQuestionSeconds;
  final int totalQuestions;
  final int attemptedQuestions;

  const OverallStats({
    required this.overallAccuracy,
    required this.averageTimePerQuestionSeconds,
    required this.totalQuestions,
    required this.attemptedQuestions,
  });
}

class SessionStats {
  final int totalTimeSpent;
  final int questionsAttempted;
  final double averageTimePerQuestion;
  final double accuracy;
  final int totalQuestions;
  final int skipped;
  final int incorrect;
  final int partial;
  final int correct;
  final int totalMarks;

  const SessionStats({
    required this.totalTimeSpent,
    required this.questionsAttempted,
    required this.averageTimePerQuestion,
    required this.accuracy,
    required this.totalQuestions,
    required this.skipped,
    required this.incorrect,
    required this.partial,
    required this.correct,
    required this.totalMarks,
  });
}

Future<OverallStats> getOverallStats() async {
  final sessions = await AppDatabase.getAllSessions();
  int totalCorrect = 0;
  int totalAnswered = 0;
  int totalTime = 0;
  int totalQuestions = 0;
  int totalAttempted = 0;

  for (final s in sessions) {
    final questions = await AppDatabase.getQuestionsBySessionId(s.id);
    totalQuestions += questions.length;
    for (final q in questions) {
      totalTime += q.timeSpent;
      if (q.selectedOption != null && q.selectedOption!.isNotEmpty) {
        totalAnswered++;
        totalAttempted++;
        if (q.isCorrect) {
          totalCorrect++;
        }
      }
    }
  }

  final accuracy = totalAnswered > 0
      ? (100.0 * totalCorrect / totalAnswered)
      : 0.0;
  final avgTime = totalQuestions > 0 ? totalTime ~/ totalQuestions : 0;

  return OverallStats(
    overallAccuracy: accuracy,
    averageTimePerQuestionSeconds: avgTime,
    totalQuestions: totalQuestions,
    attemptedQuestions: totalAttempted,
  );
}

Future<SessionStats> getSessionStats(Session session) async {
  final questions = await AppDatabase.getQuestionsBySessionId(session.id);
  final total = questions.length;
  int correct = 0;
  int partial = 0;
  int incorrect = 0;
  int skipped = 0;
  int totalTime = 0;
  int totalMarks = 0;

  for (final q in questions) {
    totalTime += q.timeSpent;
    if (q.wasSkipped) {
      skipped++;
    } else {
      if (q.isCorrect) {
        correct++;
      } else if (q.isPartiallyCorrect) {
        partial++;
      } else {
        incorrect++;
      }
    }
    totalMarks += q.marks;
  }

  final attempted = correct + partial + incorrect;
  final avgTime = total > 0 ? totalTime / total : 0.0;
  final accuracy = attempted > 0 ? (100.0 * correct / attempted) : 0.0;

  return SessionStats(
    totalTimeSpent: session.totalTimeSpent,
    questionsAttempted: attempted,
    averageTimePerQuestion: avgTime,
    accuracy: accuracy,
    totalQuestions: total,
    skipped: skipped,
    incorrect: incorrect,
    partial: partial,
    correct: correct,
    totalMarks: totalMarks,
  );
}

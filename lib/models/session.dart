/// Session record. totalTimeSpent is in seconds.
class Session {
  final int id;
  final String datetime;
  final int subjectId;
  final String source;
  final int totalTimeSpent;

  const Session({
    required this.id,
    required this.datetime,
    required this.subjectId,
    required this.source,
    required this.totalTimeSpent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'datetime': datetime,
      'subject_id': subjectId,
      'source': source,
      'total_time_spent': totalTimeSpent,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int,
      datetime: map['datetime'] as String,
      subjectId: map['subject_id'] as int,
      source: map['source'] as String,
      totalTimeSpent: map['total_time_spent'] as int,
    );
  }
}

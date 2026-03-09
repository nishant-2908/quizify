/// One row = one (subject, topic) pair. Sessions reference this via subject_id.
class Subject {
  final int id;
  final String subjectName;
  final String topicName;

  const Subject({
    required this.id,
    required this.subjectName,
    required this.topicName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_name': subjectName,
      'topic_name': topicName,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int,
      subjectName: map['subject_name'] as String,
      topicName: map['topic_name'] as String,
    );
  }

  String get displayName => '$subjectName — $topicName';
}

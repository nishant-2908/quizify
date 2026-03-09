import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/question.dart';
import '../models/session.dart';
import '../models/subject.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = join(
      (await getApplicationDocumentsDirectory()).path,
      'timer_app.db',
    );
    final db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return db;
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE questions ADD COLUMN question_type TEXT DEFAULT 'multiple_choice'",
      );
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_name TEXT NOT NULL,
        topic_name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datetime TEXT NOT NULL,
        subject_id INTEGER NOT NULL,
        source TEXT NOT NULL,
        total_time_spent INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        selected_option TEXT,
        correct_option TEXT,
        time_spent INTEGER NOT NULL,
        session_id INTEGER NOT NULL,
        question_number INTEGER NOT NULL,
        question_type TEXT NOT NULL DEFAULT 'multiple_choice',
        FOREIGN KEY (session_id) REFERENCES sessions (id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_questions_session ON questions(session_id)');
    await db.execute(
        'CREATE INDEX idx_sessions_subject ON sessions(subject_id)');
  }

  // --- Subjects ---
  static Future<int> insertSubject(Subject s) async {
    final db = await database;
    final map = s.toMap()..remove('id');
    return db.insert('subjects', map);
  }

  static Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final maps = await db.query('subjects', orderBy: 'subject_name, topic_name');
    return maps.map((m) => Subject.fromMap(m)).toList();
  }

  static Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final maps = await db.query('subjects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Subject.fromMap(maps.first);
  }

  /// Returns subject id if exists (same subject_name and topic_name), else null.
  static Future<int?> findSubjectId(String subjectName, String topicName) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'subject_name = ? AND topic_name = ?',
      whereArgs: [subjectName, topicName],
    );
    if (maps.isEmpty) return null;
    return maps.first['id'] as int;
  }

  // --- Sessions ---
  static Future<int> insertSession(Session s) async {
    final db = await database;
    final map = s.toMap()..remove('id');
    return db.insert('sessions', map);
  }

  static Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'datetime DESC');
    return maps.map((m) => Session.fromMap(m)).toList();
  }

  static Future<List<Session>> getSessionsFiltered({
    int? subjectId,
    String? source,
  }) async {
    final db = await database;
    String? where;
    List<Object?>? args;
    if (subjectId != null && source != null && source.isNotEmpty) {
      where = 'subject_id = ? AND source = ?';
      args = [subjectId, source];
    } else if (subjectId != null) {
      where = 'subject_id = ?';
      args = [subjectId];
    } else if (source != null && source.isNotEmpty) {
      where = 'source = ?';
      args = [source];
    }
    final maps = await db.query(
      'sessions',
      where: where,
      whereArgs: args,
      orderBy: 'datetime DESC',
    );
    return maps.map((m) => Session.fromMap(m)).toList();
  }

  static Future<Session?> getSessionById(int id) async {
    final db = await database;
    final maps = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  // --- Questions ---
  static Future<int> insertQuestion(QuestionRecord q) async {
    final db = await database;
    final map = q.toMap()..remove('id');
    return db.insert('questions', map);
  }

  static Future<void> updateQuestion(QuestionRecord q) async {
    final db = await database;
    await db.update(
      'questions',
      q.toMap(),
      where: 'id = ?',
      whereArgs: [q.id],
    );
  }

  static Future<void> updateQuestionCorrectOption(int id, String correct) async {
    final db = await database;
    await db.update(
      'questions',
      {'correct_option': correct},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<QuestionRecord>> getQuestionsBySessionId(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'question_number',
    );
    return maps.map((m) => QuestionRecord.fromMap(m)).toList();
  }

  static Future<int> deleteQuestion(int id) async {
    final db = await database;
    return db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}

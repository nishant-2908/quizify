import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../models/session_state.dart';
import '../services/database.dart';
import 'active_session_screen.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  final _sourceController = TextEditingController();
  bool _loading = true;
  bool _addingSubject = false;
  final _newSubjectName = TextEditingController();
  final _newTopicName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _newSubjectName.dispose();
    _newTopicName.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final list = await AppDatabase.getAllSubjects();
    if (mounted) {
      setState(() {
        _subjects = list;
        _loading = false;
      });
    }
  }

  Future<void> _addSubject() async {
    final name = _newSubjectName.text.trim();
    final topic = _newTopicName.text.trim();
    if (name.isEmpty || topic.isEmpty) {
      return;
    }
    final existingId = await AppDatabase.findSubjectId(name, topic);
    if (existingId != null) {
      final sub = await AppDatabase.getSubjectById(existingId);
      if (sub != null && mounted) {
        setState(() {
          _selectedSubject = sub;
          _addingSubject = false;
          _newSubjectName.clear();
          _newTopicName.clear();
        });
      }
      return;
    }
    final id = await AppDatabase.insertSubject(Subject(id: 0, subjectName: name, topicName: topic));
    final newSub = Subject(id: id, subjectName: name, topicName: topic);
    if (mounted) {
      setState(() {
        _subjects = [..._subjects, newSub]..sort((a, b) => a.displayName.compareTo(b.displayName));
        _selectedSubject = newSub;
        _addingSubject = false;
        _newSubjectName.clear();
        _newTopicName.clear();
      });
    }
  }

  void _startSession() {
    if (_selectedSubject == null) {
      return;
    }
    final source = _sourceController.text.trim();
    final pending = PendingSession(
      subjectId: _selectedSubject!.id,
      source: source.isEmpty ? 'General' : source,
      startedAt: DateTime.now().toIso8601String(),
      questions: [QuestionState()],
    );
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => ActiveSessionScreen(pending: pending))).then((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'New Session',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              centerTitle: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
            ),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Card(
                      // no border
                      elevation: 0, // removes shadow
                      shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.book_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Subject & Topic',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Subject>(
                              initialValue: _selectedSubject,
                              decoration: InputDecoration(
                                hintText: 'Select subject & topic',
                                prefixIcon: const Icon(Icons.library_books_outlined),
                              ),
                              isExpanded: true,
                              items: _subjects
                                  .map((s) => DropdownMenuItem(
                                    value: s, 
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        s.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ))
                                  .toList(),
                              onChanged: (s) => setState(() => _selectedSubject = s),
                            ),
                            if (_addingSubject) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _newSubjectName,
                                decoration: InputDecoration(
                                  labelText: 'Subject name',
                                  prefixIcon: const Icon(Icons.subject_outlined),
                                ),
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _newTopicName,
                                decoration: InputDecoration(
                                  labelText: 'Topic name',
                                  prefixIcon: const Icon(Icons.topic_outlined),
                                ),
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(onPressed: _addSubject, child: const Text('Add Subject')),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => setState(() => _addingSubject = false),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _addingSubject = true),
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Add new subject & topic'),
                                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 0)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16 * 2),
                    Card(
                      elevation: 0, // removes shadow
                      shape: RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ), // removes border
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.source_outlined, color: Theme.of(context).colorScheme.secondary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Question Source',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _sourceController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Textbook Chapter 5, Mock Test 1',
                                prefixIcon: const Icon(Icons.description_outlined),
                                helperText: 'Optional: Specify where questions are from',
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16 * 2),
                    FilledButton.icon(
                      onPressed: _selectedSubject == null
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Start Session?'),
                                  content: const Text(
                                    'Timer will start from 00:00:00. You can attempt questions and add more as you go.',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Start'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) _startSession();
                            },
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: const Text('Start Session'),
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
    );
  }
}

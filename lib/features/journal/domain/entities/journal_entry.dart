import 'package:equatable/equatable.dart';

enum Mood { happy, sad, neutral, excited, angry }

class JournalEntry extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final Mood mood;
  final List<String> tags;
  final String? categoryId;
  final List<String> attachmentPaths;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.tags,
    this.categoryId,
    required this.attachmentPaths,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    date,
    mood,
    tags,
    categoryId,
    attachmentPaths,
  ];
}

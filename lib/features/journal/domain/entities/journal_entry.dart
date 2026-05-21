import 'package:equatable/equatable.dart';

enum Mood { happy, sad, neutral, excited, angry }

extension MoodX on Mood {
  String get emoji {
    switch (this) {
      case Mood.happy:
        return '😊';
      case Mood.sad:
        return '😔';
      case Mood.neutral:
        return '😐';
      case Mood.excited:
        return '🤩';
      case Mood.angry:
        return '😠';
    }
  }
}

class JournalEntry extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final Mood mood;
  final List<String> tags;
  final String? categoryId;
  final List<String> attachmentPaths;
  final String? summary;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.tags,
    this.categoryId,
    required this.attachmentPaths,
    this.summary,
  });

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    Mood? mood,
    List<String>? tags,
    String? categoryId,
    bool clearCategoryId = false,
    List<String>? attachmentPaths,
    String? summary,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      summary: summary ?? this.summary,
    );
  }

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
    summary,
  ];
}

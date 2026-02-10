import 'package:hive/hive.dart';

part 'journal_entry_model.g.dart';

@HiveType(typeId: 1)
class JournalEntryModel {
  static const String boxName = 'journal_entries';

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime date;

  /// Stores `Mood.index` from the domain layer.
  @HiveField(4)
  final int moodIndex;

  @HiveField(5)
  final List<String> tags;

  @HiveField(6)
  final String? categoryId;

  @HiveField(7)
  final List<String> attachmentPaths;

  @HiveField(8)
  final String? summary;

  const JournalEntryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.moodIndex,
    this.tags = const [],
    this.categoryId,
    this.attachmentPaths = const [],
    this.summary,
  });

  JournalEntryModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    int? moodIndex,
    List<String>? tags,
    String? categoryId,
    List<String>? attachmentPaths,
    String? summary,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      moodIndex: moodIndex ?? this.moodIndex,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      summary: summary ?? this.summary,
    );
  }
}

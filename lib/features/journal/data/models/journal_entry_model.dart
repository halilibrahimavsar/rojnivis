import 'package:hive/hive.dart';
import '../../domain/entities/journal_entry.dart';

part 'journal_entry_model.g.dart';

@HiveType(typeId: 1)
class JournalEntryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final int moodIndex;

  @HiveField(5)
  final List<String> tags;

  @HiveField(6)
  final String? categoryId;

  @HiveField(7)
  final List<String> attachmentPaths;

  JournalEntryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.moodIndex,
    required this.tags,
    this.categoryId,
    required this.attachmentPaths,
  });

  factory JournalEntryModel.fromEntity(JournalEntry entry) {
    return JournalEntryModel(
      id: entry.id,
      title: entry.title,
      content: entry.content,
      date: entry.date,
      moodIndex: entry.mood.index,
      tags: entry.tags,
      categoryId: entry.categoryId,
      attachmentPaths: entry.attachmentPaths,
    );
  }

  JournalEntry toEntity() {
    return JournalEntry(
      id: id,
      title: title,
      content: content,
      date: date,
      mood: Mood.values[moodIndex],
      tags: tags,
      categoryId: categoryId,
      attachmentPaths: attachmentPaths,
    );
  }
}

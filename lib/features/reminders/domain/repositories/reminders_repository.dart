import 'package:dartz/dartz.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/reminders/domain/entities/reminder.dart';

abstract class RemindersRepository {
  Future<Either<Failure, List<Reminder>>> getReminders(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<Reminder>>> getAllReminders();
  Future<Either<Failure, void>> addReminder(Reminder reminder);
  Future<Either<Failure, void>> deleteReminder(String id);
}

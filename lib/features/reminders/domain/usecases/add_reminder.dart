import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/reminders/domain/entities/reminder.dart';
import 'package:rojnivis/features/reminders/domain/repositories/reminders_repository.dart';

@injectable
class AddReminder {
  const AddReminder(this.repository);

  final RemindersRepository repository;

  Future<Either<Failure, void>> call(AddReminderParams params) {
    return repository.addReminder(params.reminder);
  }
}

class AddReminderParams extends Equatable {
  const AddReminderParams({required this.reminder});

  final Reminder reminder;

  @override
  List<Object?> get props => [reminder];
}

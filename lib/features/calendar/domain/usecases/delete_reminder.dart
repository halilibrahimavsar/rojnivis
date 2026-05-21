import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/calendar/domain/repositories/calendar_repository.dart';

@injectable
class DeleteReminder {
  const DeleteReminder(this.repository);

  final CalendarRepository repository;

  Future<Either<Failure, void>> call(DeleteReminderParams params) {
    return repository.deleteReminder(params.id);
  }
}

class DeleteReminderParams extends Equatable {
  const DeleteReminderParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

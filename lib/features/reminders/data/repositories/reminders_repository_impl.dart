import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/reminders/data/datasources/local/reminders_local_data_source.dart';
import 'package:rojnivis/core/services/notification_service.dart';
import 'package:rojnivis/features/reminders/data/models/reminder_dto.dart';
import 'package:rojnivis/features/reminders/domain/entities/reminder.dart';
import 'package:rojnivis/features/reminders/domain/repositories/reminders_repository.dart';

@LazySingleton(as: RemindersRepository)
class RemindersRepositoryImpl implements RemindersRepository {
  RemindersRepositoryImpl(this.localDataSource);

  final RemindersLocalDataSource localDataSource;

  @override
  Future<Either<Failure, List<Reminder>>> getReminders(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final dtos = await localDataSource.getReminders(startDate, endDate);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Reminder>>> getAllReminders() async {
    try {
      final dtos = await localDataSource.getAllReminders();
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReminder(Reminder reminder) async {
    try {
      final dto = ReminderDto.fromEntity(reminder);
      await localDataSource.addReminder(dto);
      await NotificationService().scheduleReminderNotification(reminder);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReminder(String id) async {
    try {
      await localDataSource.deleteReminder(id);
      await NotificationService().cancelReminderNotification(id);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

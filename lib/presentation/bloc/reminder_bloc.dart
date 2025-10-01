import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';

// Events
abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class LoadReminders extends ReminderEvent {}

class CreateReminder extends ReminderEvent {
  final String title;
  final String description;
  final DateTime dateTime;
  final ReminderFrequency frequency;
  final List<int>? customDays;
  final int? customInterval;

  const CreateReminder({
    required this.title,
    required this.description,
    required this.dateTime,
    required this.frequency,
    this.customDays,
    this.customInterval,
  });

  @override
  List<Object?> get props =>
      [title, description, dateTime, frequency, customDays, customInterval];
}

class UpdateReminder extends ReminderEvent {
  final Reminder reminder;

  const UpdateReminder(this.reminder);

  @override
  List<Object> get props => [reminder];
}

class DeleteReminder extends ReminderEvent {
  final String id;

  const DeleteReminder(this.id);

  @override
  List<Object> get props => [id];
}

class CompleteReminder extends ReminderEvent {
  final String id;

  const CompleteReminder(this.id);

  @override
  List<Object> get props => [id];
}

class PostponeReminder extends ReminderEvent {
  final String id;
  final Duration duration;

  const PostponeReminder(this.id, this.duration);

  @override
  List<Object> get props => [id, duration];
}

class SkipReminder extends ReminderEvent {
  final String id;

  const SkipReminder(this.id);

  @override
  List<Object> get props => [id];
}

class FilterReminders extends ReminderEvent {
  final ReminderStatus? status;

  const FilterReminders(this.status);

  @override
  List<Object?> get props => [status];
}

class SyncWithFirebase extends ReminderEvent {}

class WatchReminders extends ReminderEvent {}

// States
abstract class ReminderState extends Equatable {
  const ReminderState();

  @override
  List<Object?> get props => [];
}

class ReminderInitial extends ReminderState {}

class ReminderLoading extends ReminderState {}

class ReminderLoaded extends ReminderState {
  final List<Reminder> reminders;
  final List<Reminder> filteredReminders;
  final ReminderStatus? currentFilter;
  final Map<String, int>? statistics;

  const ReminderLoaded({
    required this.reminders,
    required this.filteredReminders,
    this.currentFilter,
    this.statistics,
  });

  @override
  List<Object?> get props =>
      [reminders, filteredReminders, currentFilter, statistics];

  ReminderLoaded copyWith({
    List<Reminder>? reminders,
    List<Reminder>? filteredReminders,
    ReminderStatus? currentFilter,
    Map<String, int>? statistics,
  }) {
    return ReminderLoaded(
      reminders: reminders ?? this.reminders,
      filteredReminders: filteredReminders ?? this.filteredReminders,
      currentFilter: currentFilter ?? this.currentFilter,
      statistics: statistics ?? this.statistics,
    );
  }
}

class ReminderError extends ReminderState {
  final String message;

  const ReminderError(this.message);

  @override
  List<Object> get props => [message];
}

class ReminderOperationSuccess extends ReminderState {
  final String message;

  const ReminderOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderRepository repository;
  StreamSubscription? _reminderSubscription;

  ReminderBloc({required this.repository}) : super(ReminderInitial()) {
    on<LoadReminders>(_onLoadReminders);
    on<CreateReminder>(_onCreateReminder);
    on<UpdateReminder>(_onUpdateReminder);
    on<DeleteReminder>(_onDeleteReminder);
    on<CompleteReminder>(_onCompleteReminder);
    on<PostponeReminder>(_onPostponeReminder);
    on<SkipReminder>(_onSkipReminder);
    on<FilterReminders>(_onFilterReminders);
    on<SyncWithFirebase>(_onSyncWithFirebase);
    on<WatchReminders>(_onWatchReminders);
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());

    final result = await repository.getAllReminders();
    final statsResult = await repository.getStatistics();

    result.fold(
      (error) => emit(ReminderError(error)),
      (reminders) {
        final sortedReminders = _sortReminders(reminders);
        statsResult.fold(
          (error) => emit(ReminderLoaded(
            reminders: sortedReminders,
            filteredReminders: sortedReminders,
          )),
          (stats) => emit(ReminderLoaded(
            reminders: sortedReminders,
            filteredReminders: sortedReminders,
            statistics: stats,
          )),
        );
      },
    );
  }

  Future<void> _onCreateReminder(
    CreateReminder event,
    Emitter<ReminderState> emit,
  ) async {
    final reminder = Reminder(
      id: const Uuid().v4(),
      title: event.title,
      description: event.description,
      dateTime: event.dateTime,
      frequency: event.frequency,
      status: ReminderStatus.pending,
      customDays: event.customDays,
      customInterval: event.customInterval,
      createdAt: DateTime.now(),
    );

    final result = await repository.createReminder(reminder);

    result.fold(
      (error) => emit(ReminderError(error)),
      (_) {
        emit(
            const ReminderOperationSuccess('Recordatorio creado exitosamente'));
        add(LoadReminders());
      },
    );
  }

  Future<void> _onUpdateReminder(
    UpdateReminder event,
    Emitter<ReminderState> emit,
  ) async {
    final updated = event.reminder.copyWith(updatedAt: DateTime.now());
    final result = await repository.updateReminder(updated);

    result.fold(
      (error) => emit(ReminderError(error)),
      (_) {
        emit(const ReminderOperationSuccess('Recordatorio actualizado'));
        add(LoadReminders());
      },
    );
  }

  Future<void> _onDeleteReminder(
    DeleteReminder event,
    Emitter<ReminderState> emit,
  ) async {
    final result = await repository.deleteReminder(event.id);

    result.fold(
      (error) => emit(ReminderError(error)),
      (_) {
        emit(const ReminderOperationSuccess('Recordatorio eliminado'));
        add(LoadReminders());
      },
    );
  }

  Future<void> _onCompleteReminder(
    CompleteReminder event,
    Emitter<ReminderState> emit,
  ) async {
    final result = await repository.completeReminder(event.id);

    result.fold(
      (error) => emit(ReminderError(error)),
      (_) {
        emit(const ReminderOperationSuccess('¡Recordatorio completado!'));
        add(LoadReminders());
      },
    );
  }

  Future<void> _onPostponeReminder(
    PostponeReminder event,
    Emitter<ReminderState> emit,
  ) async {
    final result = await repository.postponeReminder(event.id, event.duration);

    result.fold(
      (error) => emit(ReminderError(error)),
      (_) {
        emit(const ReminderOperationSuccess('Recordatorio aplazado'));
        add(LoadReminders());
      },
    );
  }

  Future<void> _onSkipReminder(
    SkipReminder event,
    Emitter<ReminderState> emit,
  ) async {
    final reminderResult = await repository.getReminderById(event.id);

    reminderResult.fold(
      (error) => emit(ReminderError(error)),
      (reminder) async {
        if (reminder == null) {
          emit(const ReminderError('Recordatorio no encontrado'));
          return;
        }

        final updated = reminder.copyWith(
          status: ReminderStatus.skipped,
          updatedAt: DateTime.now(),
        );

        final result = await repository.updateReminder(updated);
        result.fold(
          (error) => emit(ReminderError(error)),
          (_) {
            emit(const ReminderOperationSuccess('Recordatorio omitido'));
            add(LoadReminders());
          },
        );
      },
    );
  }

  Future<void> _onFilterReminders(
    FilterReminders event,
    Emitter<ReminderState> emit,
  ) async {
    if (state is ReminderLoaded) {
      final currentState = state as ReminderLoaded;
      final filtered = event.status == null
          ? currentState.reminders
          : currentState.reminders
              .where((r) => r.status == event.status)
              .toList();

      emit(currentState.copyWith(
        filteredReminders: _sortReminders(filtered),
        currentFilter: event.status,
      ));
    }
  }

  Future<void> _onSyncWithFirebase(
    SyncWithFirebase event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());

    final result = await repository.syncWithFirebase();

    result.fold(
      (error) => emit(ReminderError(error)),
      (_) {
        emit(const ReminderOperationSuccess('Sincronización completada'));
        add(LoadReminders());
      },
    );
  }

  Future<void> _onWatchReminders(
    WatchReminders event,
    Emitter<ReminderState> emit,
  ) async {
    await _reminderSubscription?.cancel();

    _reminderSubscription = repository.watchReminders().listen(
      (reminders) {
        if (!isClosed) {
          add(LoadReminders());
        }
      },
    );
  }

  List<Reminder> _sortReminders(List<Reminder> reminders) {
    final sorted = List<Reminder>.from(reminders);
    sorted.sort((a, b) {
      // Primero por estado (pendientes primero)
      if (a.status != b.status) {
        if (a.status == ReminderStatus.pending) return -1;
        if (b.status == ReminderStatus.pending) return 1;
        if (a.status == ReminderStatus.postponed) return -1;
        if (b.status == ReminderStatus.postponed) return 1;
      }
      // Luego por fecha
      return a.dateTime.compareTo(b.dateTime);
    });
    return sorted;
  }

  @override
  Future<void> close() {
    _reminderSubscription?.cancel();
    return super.close();
  }
}

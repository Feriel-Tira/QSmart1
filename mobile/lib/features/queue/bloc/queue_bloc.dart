import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smartqueue/core/models/models.dart';
import 'package:smartqueue/core/repositories/queue_repository.dart';
import 'package:smartqueue/core/services/error_handler.dart';

/// ============= QUEUE EVENTS =============

abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

/// Charger la liste de toutes les queues
class LoadQueuesRequested extends QueueEvent {
  const LoadQueuesRequested();
}

/// Charger les détails d'une queue spécifique
class LoadQueueDetailRequested extends QueueEvent {
  final String queueId;

  const LoadQueueDetailRequested(this.queueId);

  @override
  List<Object?> get props => [queueId];
}

/// Créer un ticket pour une queue
class CreateTicketRequested extends QueueEvent {
  final String queueId;
  final String userId;
  final int priority;

  const CreateTicketRequested({
    required this.queueId,
    required this.userId,
    this.priority = 0,
  });

  @override
  List<Object?> get props => [queueId, userId, priority];
}

/// ============= QUEUE STATES =============

abstract class QueueState extends Equatable {
  const QueueState();

  @override
  List<Object?> get props => [];
}

/// État initial
class QueueInitial extends QueueState {
  const QueueInitial();
}

/// État de chargement
class QueueLoading extends QueueState {
  const QueueLoading();
}

/// État : Queues chargées
class QueuesLoaded extends QueueState {
  final List<QueueModel> queues;

  const QueuesLoaded(this.queues);

  @override
  List<Object?> get props => [queues];
}

/// État : Détail d'une queue chargé
class QueueDetailLoaded extends QueueState {
  final QueueModel queue;

  const QueueDetailLoaded(this.queue);

  @override
  List<Object?> get props => [queue];
}

/// État : Ticket créé avec succès
class TicketCreated extends QueueState {
  final TicketModel ticket;

  const TicketCreated(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

/// État : Erreur
class QueueError extends QueueState {
  final String message;
  final String? code;

  const QueueError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// ============= QUEUE BLOC =============

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final QueueRepository queueRepository;

  QueueBloc({required this.queueRepository}) : super(const QueueInitial()) {
    on<LoadQueuesRequested>(_onLoadQueuesRequested);
    on<LoadQueueDetailRequested>(_onLoadQueueDetailRequested);
    on<CreateTicketRequested>(_onCreateTicketRequested);
  }

  /// Charger la liste des queues
  Future<void> _onLoadQueuesRequested(
    LoadQueuesRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(const QueueLoading());

    try {
      final queues = await queueRepository.loadQueues();
      emit(QueuesLoaded(queues));
    } on AppException catch (e) {
      emit(QueueError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(QueueError(message: message));
    }
  }

  /// Charger les détails d'une queue
  Future<void> _onLoadQueueDetailRequested(
    LoadQueueDetailRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(const QueueLoading());

    try {
      final queue = await queueRepository.loadQueueDetail(event.queueId);
      emit(QueueDetailLoaded(queue));
    } on AppException catch (e) {
      emit(QueueError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(QueueError(message: message));
    }
  }

  /// Créer un ticket pour une queue
  Future<void> _onCreateTicketRequested(
    CreateTicketRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(const QueueLoading());

    try {
      final ticket = await queueRepository.createTicket(event.queueId);
      emit(TicketCreated(ticket));
    } on AppException catch (e) {
      emit(QueueError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(QueueError(message: message));
    }
  }
}
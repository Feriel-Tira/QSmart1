import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smartqueue/core/models/models.dart';
import 'package:smartqueue/core/repositories/ticket_repository.dart';
import 'package:smartqueue/core/services/error_handler.dart';

/// ============= TICKET EVENTS =============

abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object?> get props => [];
}

/// Charger tous les tickets de l'utilisateur
class LoadMyTicketsRequested extends TicketEvent {
  final String userId;

  const LoadMyTicketsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Charger les détails d'un ticket
class LoadTicketDetailRequested extends TicketEvent {
  final String ticketId;

  const LoadTicketDetailRequested(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

/// Annuler un ticket
class CancelTicketRequested extends TicketEvent {
  final String ticketId;

  const CancelTicketRequested(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

/// ============= TICKET STATES =============

abstract class TicketState extends Equatable {
  const TicketState();

  @override
  List<Object?> get props => [];
}

/// État initial
class TicketInitial extends TicketState {
  const TicketInitial();
}

/// État de chargement
class TicketLoading extends TicketState {
  const TicketLoading();
}

/// État : Tickets chargés
class MyTicketsLoaded extends TicketState {
  final List<TicketModel> tickets;

  const MyTicketsLoaded(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

/// État : Détail d'un ticket chargé
class TicketDetailLoaded extends TicketState {
  final TicketModel ticket;

  const TicketDetailLoaded(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

/// État : Ticket annulé
class TicketCancelled extends TicketState {
  final String ticketId;

  const TicketCancelled(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

/// État : Erreur
class TicketError extends TicketState {
  final String message;
  final String? code;

  const TicketError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// ============= TICKET BLOC =============

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepository ticketRepository;

  TicketBloc({required this.ticketRepository}) : super(const TicketInitial()) {
    on<LoadMyTicketsRequested>(_onLoadMyTicketsRequested);
    on<LoadTicketDetailRequested>(_onLoadTicketDetailRequested);
    on<CancelTicketRequested>(_onCancelTicketRequested);
  }

  /// Charger mes tickets
  Future<void> _onLoadMyTicketsRequested(
    LoadMyTicketsRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());

    try {
      final tickets = await ticketRepository.loadMyTickets();
      emit(MyTicketsLoaded(tickets));
    } on AppException catch (e) {
      emit(TicketError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(TicketError(message: message));
    }
  }

  /// Charger les détails d'un ticket
  Future<void> _onLoadTicketDetailRequested(
    LoadTicketDetailRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());

    try {
      final ticket = await ticketRepository.loadTicketDetail(event.ticketId);
      emit(TicketDetailLoaded(ticket));
    } on AppException catch (e) {
      emit(TicketError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(TicketError(message: message));
    }
  }

  /// Annuler un ticket
  Future<void> _onCancelTicketRequested(
    CancelTicketRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());

    try {
      await ticketRepository.cancelTicket(event.ticketId);
      emit(TicketCancelled(event.ticketId));
    } on AppException catch (e) {
      emit(TicketError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(TicketError(message: message));
    }
  }
}

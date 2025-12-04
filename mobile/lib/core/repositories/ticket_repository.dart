import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smartqueue/core/models/ticket_model.dart';
import 'package:smartqueue/core/services/error_handler.dart';

/// Repository pour gérer les opérations liées aux tickets
class TicketRepository {
  final GraphQLClient graphQLClient;

  TicketRepository({required this.graphQLClient});

  /// Récupère tous les tickets de l'utilisateur actuel
  Future<List<TicketModel>> loadMyTickets() async {
    try {
      const query = r'''
        query GetMyTickets {
          myTickets {
            id
            ticketNumber
            status
            position
            estimatedWaitTime
            queueId
            queueName
            userId
            createdAt
            updatedAt
            completedAt
          }
        }
      ''';

      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null) {
        return [];
      }

      final ticketsData = result.data!['myTickets'] as List<dynamic>?;
      if (ticketsData == null) {
        return [];
      }

      return ticketsData
          .map((ticket) => TicketModel.fromJson(ticket as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Récupère les détails d'un ticket spécifique
  Future<TicketModel> loadTicketDetail(String ticketId) async {
    try {
      const query = r'''
        query GetTicketDetail($id: ID!) {
          ticket(id: $id) {
            id
            ticketNumber
            status
            position
            estimatedWaitTime
            queueId
            queueName
            userId
            userName
            userEmail
            userPhone
            createdAt
            updatedAt
            completedAt
            cancelledAt
            cancelReason
          }
        }
      ''';

      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': ticketId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null || result.data!['ticket'] == null) {
        throw const AppException(
          message: 'Ticket non trouvé',
          code: 'TICKET_NOT_FOUND',
        );
      }

      return TicketModel.fromJson(
        result.data!['ticket'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Annule un ticket de l'utilisateur
  Future<TicketModel> cancelTicket(String ticketId, {String? reason}) async {
    try {
      const mutation = r'''
        mutation CancelTicket($id: ID!, $reason: String) {
          cancelTicket(id: $id, reason: $reason) {
            id
            ticketNumber
            status
            cancelledAt
            cancelReason
            updatedAt
          }
        }
      ''';

      final variables = {
        'id': ticketId,
        if (reason != null) 'reason': reason,
      };

      final result = await graphQLClient.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null || result.data!['cancelTicket'] == null) {
        throw const AppException(
          message: 'Erreur lors de l\'annulation du ticket',
          code: 'CANCEL_TICKET_ERROR',
        );
      }

      return TicketModel.fromJson(
        result.data!['cancelTicket'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Récupère les tickets actifs d'une file d'attente
  Future<List<TicketModel>> getQueueActiveTickets(String queueId) async {
    try {
      const query = r'''
        query GetQueueActiveTickets($queueId: ID!) {
          queueActiveTickets(queueId: $queueId) {
            id
            ticketNumber
            status
            position
            estimatedWaitTime
            userName
            createdAt
          }
        }
      ''';

      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'queueId': queueId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null) {
        return [];
      }

      final ticketsData = result.data!['queueActiveTickets'] as List<dynamic>?;
      if (ticketsData == null) {
        return [];
      }

      return ticketsData
          .map((ticket) => TicketModel.fromJson(ticket as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Récupère l'historique des tickets complétés
  Future<List<TicketModel>> getTicketHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      const query = r'''
        query GetTicketHistory($limit: Int, $offset: Int) {
          ticketHistory(limit: $limit, offset: $offset) {
            id
            ticketNumber
            status
            queueName
            estimatedWaitTime
            actualServiceTime
            createdAt
            completedAt
          }
        }
      ''';

      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(query),
          variables: {
            'limit': limit,
            'offset': offset,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null) {
        return [];
      }

      final ticketsData = result.data!['ticketHistory'] as List<dynamic>?;
      if (ticketsData == null) {
        return [];
      }

      return ticketsData
          .map((ticket) => TicketModel.fromJson(ticket as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Récupère le statut actuel d'un ticket via WebSocket (pour les mises à jour temps réel)
  Stream<TicketModel> watchTicketStatus(String ticketId) {
    try {
      const subscription = r'''
        subscription OnTicketStatusChanged($id: ID!) {
          ticketStatusChanged(id: $id) {
            id
            ticketNumber
            status
            position
            estimatedWaitTime
            updatedAt
          }
        }
      ''';

      final result = graphQLClient.subscribe(
        SubscriptionOptions(
          document: gql(subscription),
          variables: {'id': ticketId},
        ),
      );

      return result
          .map((event) {
            if (event.hasException) {
              throw ErrorHandler.handleGraphQLException(event.exception!);
            }
            if (event.data == null || event.data!['ticketStatusChanged'] == null) {
              throw const AppException(
                message: 'Erreur lors de la réception du statut du ticket',
                code: 'SUBSCRIPTION_ERROR',
              );
            }
            return TicketModel.fromJson(
              event.data!['ticketStatusChanged'] as Map<String, dynamic>,
            );
          })
          .handleError((e) {
            throw ErrorHandler.handleError(e);
          });
    } catch (e) {
      return Stream.error(ErrorHandler.handleError(e));
    }
  }

  /// Récupère les notifications de position du ticket
  Stream<Map<String, dynamic>> watchQueueUpdates(String queueId) {
    try {
      const subscription = r'''
        subscription OnQueueUpdated($queueId: ID!) {
          queueUpdated(queueId: $queueId) {
            timestamp
            totalWaiting
            averageWaitTime
            ticketsProcessed
          }
        }
      ''';

      final result = graphQLClient.subscribe(
        SubscriptionOptions(
          document: gql(subscription),
          variables: {'queueId': queueId},
        ),
      );

      return result
          .map((event) {
            if (event.hasException) {
              throw ErrorHandler.handleGraphQLException(event.exception!);
            }
            if (event.data == null || event.data!['queueUpdated'] == null) {
              throw const AppException(
                message: 'Erreur lors de la réception des mises à jour de file',
                code: 'SUBSCRIPTION_ERROR',
              );
            }
            return event.data!['queueUpdated'] as Map<String, dynamic>;
          })
          .handleError((e) {
            throw ErrorHandler.handleError(e);
          });
    } catch (e) {
      return Stream.error(ErrorHandler.handleError(e));
    }
  }
}

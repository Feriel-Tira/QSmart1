import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smartqueue/core/models/queue_model.dart';
import 'package:smartqueue/core/models/ticket_model.dart';
import 'package:smartqueue/core/services/error_handler.dart';

/// Repository pour gérer les opérations liées aux files d'attente
class QueueRepository {
  final GraphQLClient graphQLClient;

  QueueRepository({required this.graphQLClient});

  /// Récupère la liste de toutes les files d'attente
  Future<List<QueueModel>> loadQueues() async {
    try {
      const query = r'''
        query GetQueues {
          queues {
            id
            name
            description
            isActive
            estimatedTime
            currentTickets
            maxCapacity
            createdAt
            updatedAt
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
        throw const AppException(
          message: 'Aucune file d\'attente disponible',
          code: 'NO_QUEUES',
        );
      }

      final queuesData = result.data!['queues'] as List<dynamic>;
      return queuesData
          .map((queue) => QueueModel.fromJson(queue as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Récupère les détails d'une file d'attente spécifique avec ses tickets
  Future<QueueModel> loadQueueDetail(String queueId) async {
    try {
      const query = r'''
        query GetQueueDetail($id: ID!) {
          queue(id: $id) {
            id
            name
            description
            isActive
            estimatedTime
            currentTickets
            maxCapacity
            activeTickets {
              id
              ticketNumber
              status
              position
              userId
              createdAt
            }
            stats {
              totalToday
              averageServiceTime
              maxActive
              completedTickets
            }
            createdAt
            updatedAt
          }
        }
      ''';

      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': queueId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null || result.data!['queue'] == null) {
        throw const AppException(
          message: 'File d\'attente non trouvée',
          code: 'QUEUE_NOT_FOUND',
        );
      }

      return QueueModel.fromJson(
        result.data!['queue'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Crée un nouveau ticket dans la file d'attente
  Future<TicketModel> createTicket(String queueId) async {
    try {
      const mutation = r'''
        mutation CreateTicket($queueId: ID!) {
          createTicket(queueId: $queueId) {
            id
            ticketNumber
            status
            position
            estimatedWaitTime
            queueId
            userId
            createdAt
            updatedAt
          }
        }
      ''';

      final result = await graphQLClient.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'queueId': queueId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null || result.data!['createTicket'] == null) {
        throw const AppException(
          message: 'Erreur lors de la création du ticket',
          code: 'CREATE_TICKET_ERROR',
        );
      }

      return TicketModel.fromJson(
        result.data!['createTicket'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Récupère les statistiques d'une file d'attente
  Future<Map<String, dynamic>> getQueueStats(String queueId) async {
    try {
      const query = r'''
        query GetQueueStats($id: ID!) {
          queueStats(id: $id) {
            totalTickets
            completedTickets
            averageServiceTime
            currentWaitingCount
            peakHourWaitTime
            satisfactionRate
          }
        }
      ''';

      final result = await graphQLClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': queueId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw ErrorHandler.handleGraphQLException(result.exception!);
      }

      if (result.data == null) {
        return {};
      }

      return result.data!['queueStats'] as Map<String, dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Met à jour la file d'attente (admin only)
  Future<QueueModel> updateQueue({
    required String queueId,
    String? name,
    String? description,
    bool? isActive,
    int? maxCapacity,
  }) async {
    try {
      const mutation = r'''
        mutation UpdateQueue(
          $id: ID!
          $name: String
          $description: String
          $isActive: Boolean
          $maxCapacity: Int
        ) {
          updateQueue(
            id: $id
            name: $name
            description: $description
            isActive: $isActive
            maxCapacity: $maxCapacity
          ) {
            id
            name
            description
            isActive
            maxCapacity
            updatedAt
          }
        }
      ''';

      final variables = {
        'id': queueId,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isActive != null) 'isActive': isActive,
        if (maxCapacity != null) 'maxCapacity': maxCapacity,
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

      if (result.data == null || result.data!['updateQueue'] == null) {
        throw const AppException(
          message: 'Erreur lors de la mise à jour de la file',
          code: 'UPDATE_QUEUE_ERROR',
        );
      }

      return QueueModel.fromJson(
        result.data!['updateQueue'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}

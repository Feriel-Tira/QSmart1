class AuthMutations {
  static const String login = '''
    mutation LoginUser(\$email: String!, \$password: String!) {
      loginUser(email: \$email, password: \$password) {
        token
        user {
          id
          name
          email
          phone
        }
      }
    }
  ''';

  static const String register = '''
    mutation RegisterUser(
      \$name: String!
      \$email: String!
      \$password: String!
      \$phone: String
    ) {
      registerUser(
        name: \$name
        email: \$email
        password: \$password
        phone: \$phone
      ) {
        token
        user {
          id
          name
          email
          phone
        }
      }
    }
  ''';
}

class QueueQueries {
  static const String getQueues = '''
    query GetQueues {
      queues {
        id
        name
        description
        isActive
        maxActiveTickets
        currentTicket {
          ticketNumber
        }
      }
    }
  ''';

  static const String getQueue = '''
    query GetQueue(\$id: ID!) {
      queue(id: \$id) {
        id
        name
        description
        isActive
        tickets {
          id
          ticketNumber
          position
          status
          estimatedWaitTime
        }
        stats {
          averageWaitTime
          ticketsServedToday
          activeTickets
        }
      }
    }
  ''';
}

class TicketMutations {
  static const String createTicket = '''
    mutation CreateTicket(\$queueId: ID!, \$priority: Priority) {
      createTicket(queueId: \$queueId, priority: \$priority) {
        id
        ticketNumber
        position
        estimatedWaitTime
        status
        queue {
          name
        }
      }
    }
  ''';

  static const String cancelTicket = '''
    mutation CancelTicket(\$ticketId: ID!) {
      cancelTicket(ticketId: \$ticketId) {
        id
        status
      }
    }
  ''';
}

class UserQueries {
  static const String getMyTickets = '''
    query GetMyTickets {
      myTickets {
        id
        ticketNumber
        position
        estimatedWaitTime
        status
        createdAt
        queue {
          id
          name
        }
      }
    }
  ''';

  static const String getProfile = '''
    query GetProfile {
      me {
        id
        name
        email
        phone
      }
    }
  ''';
}
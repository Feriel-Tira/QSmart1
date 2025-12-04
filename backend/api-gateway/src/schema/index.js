const { gql } = require('apollo-server');

module.exports = gql`
  type Queue {
    id: ID!
    name: String!
    waitingCount: Int!
  }

  type Query {
    queues: [Queue!]!
  }

    type Ticket {
    id: ID!
    number: Int!
    userId: String
    status: String!
  }
    type Mutation {
    createTicket(userId: String!): Ticket!
  }
`;

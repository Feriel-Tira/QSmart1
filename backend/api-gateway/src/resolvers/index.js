module.exports = {
  Query: {
    queues: async (_, __, { dataSources }) => {
      return dataSources.queueAPI.getQueues();
    }
  },
  Mutation: {
    createTicket: async (_, { userId }, { dataSources }) => {
      return dataSources.queueAPI.createTicket(userId);
    }
  }
};

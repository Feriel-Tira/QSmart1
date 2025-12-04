const axios = require("axios");

class QueueAPI {
  constructor() {
    this.baseURL = process.env.QUEUE_SERVICE_URL || "http://localhost:4001";
  }

  async getQueues() {
    const res = await axios.get(`${this.baseURL}/queues`);
    return res.data;
  }

  async createTicket(userId) {
    const res = await axios.post(`${this.baseURL}/tickets`, { userId });
    return res.data;
  }
}


module.exports = QueueAPI;

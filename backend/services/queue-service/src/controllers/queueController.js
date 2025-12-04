const Queue = require('../models/Queue');
const { asyncHandler, AppError } = require('../../middleware/errorHandler');
const serviceClient = require('../../utils/serviceClient');

exports.getAllQueues = asyncHandler(async (req, res) => {
  const queues = await Queue.find({ isActive: true });
  res.json({ success: true, data: queues });
});

exports.getQueueById = asyncHandler(async (req, res) => {
  const queue = await Queue.findById(req.params.id);
  if (!queue) {
    throw new AppError('Queue not found', 404);
  }
  res.json({ success: true, data: queue });
});

exports.createQueue = asyncHandler(async (req, res) => {
  const { name, description, maxActiveTickets, averageServiceTime } = req.body;
  
  if (!name) {
    throw new AppError('Le nom de la queue est requis', 400);
  }

  const queue = new Queue({
    name,
    description,
    maxActiveTickets: maxActiveTickets || 5,
    averageServiceTime: averageServiceTime || 300,
  });
  
  await queue.save();
  
  // Notifier le service de notification
  try {
    await serviceClient.post('notification', '/api/notifications/queue-created', {
      queueId: queue._id,
      queueName: queue.name,
    });
  } catch (error) {
    console.warn('⚠️  Notification service not available, continuing anyway');
  }

  res.status(201).json({ success: true, data: queue });
});

exports.updateQueue = asyncHandler(async (req, res) => {
  const queue = await Queue.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true, runValidators: true }
  );
  
  if (!queue) {
    throw new AppError('Queue not found', 404);
  }
    
  res.json({ success: true, data: queue });
});

exports.deleteQueue = asyncHandler(async (req, res) => {
  const queue = await Queue.findByIdAndUpdate(
    req.params.id,
    { isActive: false },
    { new: true }
  );
  
  if (!queue) {
    throw new AppError('Queue not found', 404);
  }
  
  res.json({ success: true, message: 'Queue deactivated successfully', data: queue });
});
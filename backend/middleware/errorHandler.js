/**
 * Middleware de gestion d'erreurs globale
 */

class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
    this.timestamp = new Date().toISOString();
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Middleware d'erreur global (à ajouter en dernier dans Express)
 */
const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Erreur serveur interne';

  // Log de l'erreur
  console.error(`❌ [${new Date().toISOString()}] ${statusCode} - ${message}`);
  if (process.env.LOG_LEVEL === 'debug') {
    console.error(err.stack);
  }

  // Réponse d'erreur structurée
  res.status(statusCode).json({
    success: false,
    error: {
      message,
      statusCode,
      timestamp: err.timestamp || new Date().toISOString(),
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    },
  });
};

/**
 * Wrapper pour async/await - évite try/catch partout
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

/**
 * Validateur simple pour les inputs
 */
const validateInput = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Validation échouée',
          details: error.details.map(d => d.message),
        },
      });
    }
    req.validatedData = value;
    next();
  };
};

module.exports = {
  AppError,
  errorHandler,
  asyncHandler,
  validateInput,
};

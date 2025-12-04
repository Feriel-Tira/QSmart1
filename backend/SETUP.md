# 🚀 Configuration Backend - SmartQueue

## **Fichiers Créés/Modifiés**

### ✅ 1. `.env` (Configuration d'environnement)
- Tous les ports des services
- URLs inter-services (Docker et local)
- Variables de sécurité (JWT)
- Configuration notification et logging

**Comment utiliser:**
```bash
# Le fichier .env est automatiquement chargé au démarrage
# via require('dotenv').config() dans config/environment.js
```

---

### ✅ 2. `config/environment.js` (Configuration centralisée avec validation)
- Charge et valide les variables d'environnement
- Détecte automatiquement le mode (Docker vs Local)
- Expose une API simple pour accéder aux configs

**Utilisation dans les services:**
```javascript
const config = require('../../config/environment');

// Accéder à la configuration
const port = config.services.queue.port;
const mongoUri = config.mongodb.uri;
const jwtSecret = config.jwt.secret;
```

---

### ✅ 3. `middleware/errorHandler.js` (Gestion d'erreurs globale)

**Contient:**
- `AppError` - Classe d'erreur personnalisée
- `errorHandler` - Middleware global pour Express
- `asyncHandler` - Wrapper pour async/await (évite try/catch partout)
- `validateInput` - Validateur simple

**Utilisation:**

```javascript
const { errorHandler, asyncHandler, AppError } = require('../../middleware/errorHandler');

// Dans une route
app.post('/api/queue', asyncHandler(async (req, res) => {
  if (!req.body.name) {
    throw new AppError('Le nom est requis', 400);
  }
  // Logic...
}));

// Ajouter le middleware en dernier dans Express
app.use(errorHandler);
```

---

### ✅ 4. API Gateway mise à jour
- Utilise la configuration centralisée
- CORS correctement configuré
- Middleware d'erreur activé
- Logging amélioré

---

## **📋 Checklist Intégration**

Voici comment intégrer cela dans les autres services:

### **Queue Service** (`services/queue-service/src/index.js`)
```javascript
const config = require('../../config/environment');
const { errorHandler, asyncHandler } = require('../../middleware/errorHandler');

mongoose.connect(config.mongodb.uri)
  .then(() => console.log('✅ MongoDB connecté'))
  .catch(err => {
    throw new AppError('Erreur MongoDB', 500);
  });

app.listen(config.services.queue.port, () => {
  console.log(`🚀 Queue Service port ${config.services.queue.port}`);
});

// En dernier
app.use(errorHandler);
```

### **Ticket Service** (`services/ticket-service/src/index.js`)
```javascript
const config = require('../../config/environment');
const { errorHandler } = require('../../middleware/errorHandler');

mongoose.connect(config.mongodb.uri);
app.listen(config.services.ticket.port);
app.use(errorHandler);
```

### **Autres Services** (User, Analytics, Notification)
Même pattern que Ticket Service

---

## **🧪 Test de la Configuration**

Démarrer l'API Gateway et vérifier:

```bash
# Vérifier health
curl http://localhost:4000/health

# Réponse attendue:
{
  "status": "OK",
  "service": "smartqueue-api-gateway",
  "version": "1.0.0",
  "environment": "development",
  "timestamp": "2025-12-03T...",
  "message": "✅ API Gateway opérationnelle"
}
```

---

## **🔒 Important en Production**

1. **Changer le JWT_SECRET** dans `.env`
2. **Vérifier la CORS_ORIGIN** pour correspondre aux domaines réels
3. **Mettre NODE_ENV=production**
4. **Utiliser des URLs MongoDB sécurisées** (pas d'auth par défaut)
5. **Générer un nouveau JWT_SECRET** sécurisé
   ```bash
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

---

## **📁 Fichiers Créés**

```
backend/
├── .env (mis à jour)
├── .env.example (nouveau)
├── config/
│   └── environment.js (nouveau)
├── middleware/
│   └── errorHandler.js (nouveau)
├── api-gateway/
│   └── src/index.js (mis à jour)
```

---

## **✅ Prochaines Étapes**

1. Intégrer `config` et `errorHandler` dans les services
2. Ajouter middleware d'erreurs globales partout
3. Tester Docker Compose avec la nouvelle config
4. Passer à la **Tâche 2: Communication inter-services**


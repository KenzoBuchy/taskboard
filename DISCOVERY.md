# DISCOVERY.md

## Variables d'environnement

y'en a 3 :
- `DATABASE_URL` -> l'url postgres, obligatoire
- `JWT_SECRET` -> la clé pour signer les tokens JWT, obligatoire
- `PORT` -> optionnel, défaut 3000

si DATABASE_URL ou JWT_SECRET sont pas définis l'app démarre quand même mais ça crash dès qu'on fait une requête

## Services externes

juste postgres, c'est tout. pas de redis, pas de truc externe. la base est initialisée automatiquement au démarrage (création des tables + user admin par défaut)

## Scripts package.json

- `npm start` -> lance le serveur
- `npm run dev` -> pareil mais avec --watch donc ça redémarre tout seul
- `npm test` -> lance les tests jest
- `npm run test:coverage` -> tests + rapport de couverture
- `npm run lint` -> eslint sur src/

## Problèmes de sécurité

### injection SQL (grave)

dans `src/models/task.js` ligne 16 :

```js
const result = await pool.query(`SELECT * FROM tasks WHERE status = '${status}'`);
```

le status vient direct du query string sans aucune vérification, c'est une injection SQL classique.

### le .env est commité

le fichier .env est dans le repo avec le vrai JWT_SECRET dedans (mysupersecretkey123).

### mot de passe admin en dur

à chaque démarrage si y'a pas d'utilisateur, il crée admin/admin123. c'est dans le code donc tout le monde le sait. en prod c'est problématique, il vaudrait mieux le mettre dans le .env.

### erreurs trop verbeuses

le error handler renvoie `err.message` directement au client, donc si postgres plante il va renvoyer le message d'erreur postgres avec les noms de tables etc

### pas de rate limiting sur le login

on peut bruteforcer /auth/login sans aucune limite

### autres trucs mineurs

- CORS complètement ouvert (toutes origines acceptées)
- pas de validation sur POST /tasks (title peut être vide, l'erreur vient de postgres)
- /metrics répond 501, pas encore implémenté

---
name: backend-dev-rules
description: Règles de développement backend à appliquer en écrivant du code serveur - conception d'API (erreurs RFC 9457, idempotence, pagination par curseur, versionnement), validation, accès aux données et migrations, résilience (timeouts, retries), observabilité OpenTelemetry, tests. À utiliser pour tout endpoint, service, requête de base ou tâche de fond.
---

# Règles de développement backend

À appliquer en écrivant tout code serveur, quel que soit le langage ou le framework.

## 1. API

- **Contrat d'abord** : l'API est décrite (OpenAPI ou schéma équivalent) et le code s'y conforme.
- Ressources au pluriel, verbes HTTP et codes de statut corrects (`201` création, `204` sans
  contenu, `400/401/403/404/409/422/429`).
- **Erreurs au format RFC 9457** (`application/problem+json` : `type`, `title`, `status`,
  `detail`, `instance`). Jamais de stack trace ni de détail interne dans une réponse.
- **Idempotence** : toute opération non idempotente qui peut être rejouée (paiement, création,
  envoi) accepte un en-tête `Idempotency-Key` et renvoie le même résultat au rejeu.
- **Pagination obligatoire** sur toute liste, avec limite maximale côté serveur. Curseur pour
  les grands jeux de données qui changent ; offset acceptable pour les petits écrans d'admin.
- **Versionnement** dès le premier jour, au niveau de l'API ; pas de changement cassant dans
  une version publiée.
- Limitation de débit, `ETag`/requêtes conditionnelles quand c'est utile, identifiant de
  corrélation propagé dans chaque requête et chaque log.
- Webhooks sortants signés (HMAC-SHA256), entrants vérifiés et idempotents.
- Voir `api-designer` pour la modélisation détaillée.

## 2. Validation et frontières

- Valider **toute entrée à la frontière** avec un schéma (type, format, bornes, taille) ;
  rejeter ce qui n'est pas attendu plutôt que tenter de le nettoyer.
- Types distincts pour l'entrée, le domaine et la sortie : ne jamais exposer une entité de base
  telle quelle, ni accepter un objet client pour mettre à jour une entité (mass assignment).
- Autorisation vérifiée côté serveur sur chaque objet accédé (voir `owasp-security-audit`).

## 3. Données

- Requêtes paramétrées uniquement. Pas de requête dans une boucle (N+1) : charger en lot.
- Transactions courtes, explicites, sans appel réseau à l'intérieur.
- Index pour chaque colonne de filtre, de tri et de jointure fréquente ; vérifier le plan
  d'exécution des requêtes importantes (`database-optimizer`).
- **Migrations sans interruption** en deux temps (expand / contract) : ajouter de façon
  compatible, déployer le code, migrer les données, puis supprimer l'ancien. Jamais de
  renommage ou suppression de colonne dans le même déploiement que le code qui en dépend.
- Migrations versionnées, réversibles quand c'est possible, testées sur une copie réaliste.
- Pool de connexions dimensionné ; dates en UTC ; montants en entiers (centimes) ou décimal,
  jamais en flottant.

## 4. Résilience

- **Timeout sur tout appel sortant** (HTTP, base, cache, file). Un appel sans timeout est une
  fuite de ressources.
- Retries seulement sur erreurs transitoires et opérations idempotentes, avec backoff
  exponentiel et jitter, plafonnés (3 à 5).
- Disjoncteur et repli pour les dépendances non critiques ; isolation des ressources par
  dépendance.
- Travail long hors de la requête : file de tâches, tâches idempotentes et rejouables, file
  de lettres mortes surveillée.
- Publication d'événements par outbox, dans la même transaction que la donnée.
- Arrêt propre : finir les requêtes et tâches en cours avant de quitter.

## 5. Observabilité

- **OpenTelemetry** par défaut : traces, métriques et logs corrélés par identifiant de trace.
- Logs structurés (JSON), niveau adapté, sans secret ni donnée personnelle.
- Métriques par endpoint : débit, taux d'erreur, latence (p50/p95/p99). Endpoints de santé
  `live` et `ready`.
- Une erreur est soit traitée, soit journalisée avec son contexte et propagée. Jamais avalée.

## 6. Tests

- Tests unitaires sur la logique métier, sans base ni réseau.
- Tests d'intégration sur une vraie base (conteneur), pas sur un mock de base.
- Tests de contrat de l'API ; au moins un test par endpoint couvrant succès, entrée invalide et
  accès refusé.
- Un bug corrigé = un test qui le reproduit.

## 7. À vérifier avant de finir

1. Entrées validées, erreurs en RFC 9457, codes de statut justes ?
2. Liste paginée et bornée ? Opération rejouable sans doublon ?
3. Timeout sur chaque appel sortant ? Requêtes sans N+1 ?
4. Migration compatible avec la version précédente du code ?
5. Logs, traces et métriques en place ? Tests écrits et passants ?

Skills complémentaires : `api-designer`, `database-optimizer`, `monitoring-expert`,
`test-master`, et le skill du framework utilisé (`nestjs-expert`, `fastapi-expert`,
`django-expert`, `laravel-specialist`, `rails-expert`, `spring-boot-engineer`…).

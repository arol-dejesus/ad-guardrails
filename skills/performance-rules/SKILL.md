---
name: performance-rules
description: Règles de performance et de montée en charge à appliquer à tout code - cible minimale de 10 000 utilisateurs, budgets de latence, requêtes et index, cache, pool de connexions, traitements asynchrones, Core Web Vitals côté web, fluidité côté mobile, tests de charge. À utiliser pour tout endpoint, requête, écran, liste, boucle ou choix d'infrastructure.
---

# Règles de performance — cible : au moins 10 000 utilisateurs

Tout ce qui est conçu ou écrit doit tenir **au moins 10 000 utilisateurs** sans réécriture.

**Hypothèse de dimensionnement** (à ajuster si l'utilisateur donne d'autres chiffres) :
10 000 utilisateurs actifs, dont jusqu'à 10 000 connectés en même temps au pic ; des tables de
plusieurs millions de lignes ; un pic à au moins 3 fois le trafic moyen. Écrire chaque requête,
liste et boucle comme si la table contenait déjà ces volumes, pas les 20 lignes de développement.

## 1. Budgets à respecter

| Mesure | Budget |
|---|---|
| Latence API en lecture | p95 ≤ 200 ms, p99 ≤ 500 ms |
| Latence API en écriture | p95 ≤ 500 ms |
| Requête de base sur un chemin chaud | ≤ 50 ms, toujours sur index |
| Taux d'erreur sous charge nominale | < 0,1 % |
| Web : LCP / INP / CLS (75e centile, mobile) | ≤ 2,5 s / ≤ 200 ms / ≤ 0,1 |
| Mobile : fluidité | 60 images/s, aucune image > 16 ms sur les écrans courants |
| Mobile : démarrage à froid | ≤ 2 s jusqu'au premier écran utilisable |

Un budget dépassé est un défaut à corriger ou à signaler, pas un détail.

## 2. Base de données (premier goulot à 10 000 utilisateurs)

- Aucune requête dans une boucle (N+1) : chargement en lot, jointure ou `IN`.
- Index sur chaque colonne de filtre, de tri et de jointure des chemins chauds ; vérifier le
  plan d'exécution (`EXPLAIN`) avant de livrer une requête importante.
- Jamais de `SELECT *` ni de lecture de table entière : ne charger que les colonnes et les
  lignes nécessaires. Toute liste est paginée et bornée côté serveur.
- **Pool de connexions** obligatoire et dimensionné (PgBouncer ou équivalent si besoin) : à
  10 000 connexions simultanées, la base manque de connexions avant de manquer de CPU.
- Transactions courtes ; pas de verrou tenu pendant un appel réseau.
- Agrégats et compteurs coûteux : précalculés ou mis en cache, pas recalculés à chaque requête.
- Lectures lourdes séparables vers un réplica ; écritures en lot quand c'est possible.

## 3. Cache

- Mettre en cache ce qui est lu souvent et change peu : niveau HTTP (`Cache-Control`, `ETag`,
  CDN pour le statique), puis cache applicatif (Redis), avec une durée de vie explicite.
- Toute entrée de cache a une stratégie d'invalidation décidée à l'écriture, pas après coup.
- Se protéger de la ruée sur cache expiré (verrou ou rafraîchissement anticipé) et ne jamais
  dépendre du cache pour l'exactitude : le service doit fonctionner, plus lentement, sans lui.

## 4. Serveur d'application

- Sans état, pour pouvoir ajouter des instances derrière un répartiteur de charge.
- E/S non bloquantes ; jamais de travail CPU long ni d'appel lent synchrone dans une requête.
- Travail long ou différable (e-mail, export, image, notification, appel tiers lent) → file de
  tâches, avec réponse immédiate au client.
- Appels sortants indépendants en parallèle, avec timeout ; pas d'appels en cascade en série.
- Réponses compressées, charges utiles réduites au nécessaire, flux (streaming) pour les gros volumes.
- Limitation de débit par utilisateur et par IP pour qu'un client ne dégrade pas les autres.
- Complexité : pas d'algorithme quadratique sur une collection non bornée ; pas de chargement
  de collection entière en mémoire.

## 5. Frontend web

- Budget JavaScript initial maîtrisé : découpage par route, chargement différé de ce qui n'est
  pas visible, pas de dépendance lourde pour un petit besoin.
- Images dimensionnées, formats modernes, chargement différé hors écran ; taille réservée pour
  éviter les décalages de mise en page (CLS).
- Longues listes virtualisées ; saisies coûteuses temporisées (debounce) ; pas de rendu inutile.
- Données : pas de cascade de requêtes au chargement ; regrouper, précharger, mettre en cache.

## 6. Mobile (Flutter et autres)

- Listes construites à la demande (`ListView.builder` ou équivalent), jamais toute la liste.
- Widgets `const` quand c'est possible ; reconstructions limitées au plus petit sous-arbre.
- Aucun travail lourd sur le fil d'interface : calcul, parsing JSON volumineux et E/S dans un
  isolate ou en arrière-plan.
- Images mises en cache et redimensionnées à la taille d'affichage.
- Pagination et cache local des données ; l'application reste utilisable sur réseau lent.

## 7. Mesurer, pas supposer

- Pas d'optimisation à l'aveugle : mesurer d'abord (profilage, traces, plan d'exécution), puis
  corriger le vrai goulot.
- Tout chemin critique a ses métriques : débit, taux d'erreur, latence p50/p95/p99.
- **Test de charge avant mise en production** de toute fonctionnalité exposée (k6, Locust ou
  équivalent) : charge nominale, pic à 3 fois, et endurance. Le scénario cible les 10 000
  utilisateurs de l'hypothèse ci-dessus.
- Ne jamais annoncer qu'un code « tient 10 000 utilisateurs » sans l'avoir mesuré : dire ce
  qui a été conçu pour, et ce qui reste à vérifier par un test de charge.

## 8. À vérifier avant de finir

1. Combien de requêtes de base par appel ? Sont-elles sur index et bornées ?
2. Que se passe-t-il avec 1 000 fois plus de lignes et 10 000 utilisateurs en même temps ?
3. Qu'est-ce qui peut être mis en cache, et comment est-ce invalidé ?
4. Y a-t-il un travail long à sortir de la requête ?
5. Le budget de latence est-il mesuré, ou au moins mesurable ?

Skills complémentaires : `database-optimizer`, `postgres-pro`, `monitoring-expert`,
`sre-engineer`, `backend-dev-rules`, et l'agent `performance-engineer` pour un diagnostic approfondi.

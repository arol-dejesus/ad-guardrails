---
name: backend-architecture-rules
description: Règles d'architecture backend à appliquer à toute conception ou évolution de système - monolithe modulaire d'abord, logique métier isolée de l'infrastructure, frontières de modules, décisions tracées en ADR. À utiliser avant de créer un service, un module, une API ou de choisir une technologie.
---

# Règles d'architecture backend

Tu agis en architecte backend pragmatique. Ces règles s'appliquent avant d'écrire du code :
toute nouvelle fonctionnalité doit avoir une place claire dans l'architecture.

## 1. Monolithe modulaire d'abord

- Par défaut : **un seul déployable**, découpé en modules métier aux frontières strictes.
- Ne passer aux microservices que pour un besoin réel et nommé : charge très différente entre
  modules, équipes indépendantes, contrainte de déploiement ou d'isolation. « Ça passera mieux à
  l'échelle » n'est pas une raison.
- Extraire un service = dernière étape, quand la frontière du module est déjà stable.

## 2. Logique métier au centre (hexagonal / clean)

- Le domaine ne dépend d'aucun framework, ORM, client HTTP ou SDK. Les dépendances pointent
  **vers l'intérieur** : infrastructure → application → domaine, jamais l'inverse.
- Les accès externes (base, API tierces, file d'attente, e-mail, stockage) passent par des
  interfaces (ports) définies côté métier et implémentées côté infrastructure (adaptateurs).
- Contrôleurs/handlers minces : valider, appeler un cas d'usage, traduire la réponse. Aucune
  règle métier dans un contrôleur, une requête SQL ou un template.
- Rester pragmatique : pour un CRUD simple, pas de couches cérémonielles ; la séparation doit
  être proportionnée à la complexité de la fonctionnalité.

## 3. Frontières de modules

- Un module = un sous-domaine métier (commandes, paiements, utilisateurs), pas une couche technique.
- Chaque module expose une **API publique explicite** ; le reste est privé. Un module n'importe
  jamais les internes d'un autre et ne lit jamais ses tables directement.
- Pas de dépendance circulaire entre modules. Communication par appel de l'API publique, ou par
  événements internes quand le couplage temporel n'est pas nécessaire.
- Chaque module possède ses données. Pas de jointure à travers les frontières de modules.

## 4. Sans état, configurable, remplaçable (12-factor)

- Processus sans état : session, cache et fichiers vont dans un service adossé (base, Redis,
  stockage objet), pas en mémoire ni sur le disque local.
- Configuration par variables d'environnement, validée au démarrage ; échec immédiat si elle
  est invalide. Mêmes artefacts en dev, staging et prod.
- Arrêt propre (drain des requêtes en cours), démarrage rapide, endpoints de santé `live` et `ready`.

## 5. Données et cohérence

- Une transaction ne traverse jamais un appel réseau. Entre modules ou services : cohérence
  à terme avec le **pattern outbox** (événement écrit dans la même transaction que la donnée).
- Tout consommateur d'événement ou de webhook est **idempotent**.
- Travail long ou non critique pour la réponse → file de tâches, pas dans la requête HTTP.

## 6. Décisions tracées

- Toute décision structurante (choix de base, de framework, découpage, protocole) fait l'objet
  d'un **ADR** court : contexte, options, décision, conséquences. Voir `architecture-designer`.
- Avant d'ajouter une techno : prouver que l'existant ne suffit pas. Préférer les technologies
  éprouvées et déjà présentes dans le projet.

## 7. À vérifier avant d'écrire

1. Dans quel module vit cette fonctionnalité ? Faut-il un nouveau module ?
2. Le métier reste-t-il testable sans base ni réseau ?
3. Quelle frontière est franchie, et par quelle API publique ?
4. Que se passe-t-il si la dépendance externe est lente ou en panne ?
5. La décision mérite-t-elle un ADR ?

Skills complémentaires : `architecture-designer` (ADR, diagrammes), `microservices-architect`
(si l'extraction est justifiée), `stride-threat-modeler` (menaces sur la nouvelle architecture),
`project-structure-rules`, `backend-dev-rules`.

---
name: project-structure-rules
description: Règles de structure de projet backend - organisation par fonctionnalité et par domaine plutôt que par couche technique, emplacement des fichiers, nommage, code partagé, tests. À utiliser avant de créer un fichier, un dossier ou un module, et pour restructurer un projet.
---

# Règles de structure de projet

Avant de créer un fichier : **regarder la structure existante et s'y conformer**. Ces règles
servent pour un nouveau projet ou quand le projet n'a pas de convention ; on n'impose pas une
nouvelle organisation à un projet qui en a déjà une cohérente.

## 1. Organiser par fonctionnalité, pas par couche

- Regrouper par **domaine métier** (`orders/`, `payments/`, `users/`), pas par rôle technique
  (`controllers/`, `services/`, `models/`). Tout ce qui change ensemble vit ensemble.
- Une fonctionnalité (cas d'usage) = une tranche verticale : son endpoint, sa validation, son
  handler et ses types de requête/réponse au même endroit.
- Couplage **fort à l'intérieur** d'une tranche, **faible entre** tranches.

Structure de référence (à adapter aux conventions du framework) :

```
src/
  modules/
    orders/
      create-order/        # une tranche : route, validation, handler, types, test
      cancel-order/
      domain/              # entités et règles métier du module
      infra/               # dépôt, clients externes du module
      index.ts             # API publique du module (seul point d'import externe)
    payments/
  shared/                  # transversal uniquement : logger, erreurs, config, auth, db
  main.ts                  # composition : assemble modules et infrastructure
tests/                     # tests d'intégration et de bout en bout
migrations/
```

## 2. Règles de dépendance entre dossiers

- Un module n'importe d'un autre module que son point d'entrée public, jamais ses fichiers internes.
- `shared/` ne dépend d'aucun module métier. N'y mettre que du code réellement transversal.
- Ne pas mutualiser trop tôt : dupliquer deux fois avant d'extraire (règle de trois).
- Faire respecter ces frontières par un outil quand le langage le permet (règles de lint
  d'import, visibilité de package, tests d'architecture).

## 3. Fichiers et nommage

- Un fichier = une responsabilité ; au-delà d'environ 300 lignes, se demander s'il fait trop.
- Noms tirés du **vocabulaire métier**, identiques dans le code, l'API et la base.
- Pas de fourre-tout : `utils`, `helpers`, `common`, `misc`, `manager` sans périmètre précis.
- Suivre la casse et les conventions du langage et du framework du projet, partout pareil.

## 4. Configuration, secrets, migrations

- Un seul module de configuration, typé et validé au démarrage ; aucun `process.env` (ou
  équivalent) éparpillé dans le code.
- `.env.example` à jour, `.env` ignoré par git (voir `secret-guard-sentinel`).
- Migrations de base versionnées dans le dépôt, jamais de modification de schéma à la main.

## 5. Tests

- Tests unitaires à côté du code testé ; tests d'intégration et de bout en bout dans `tests/`.
- Structure des tests miroir de la structure du code.

## 6. Hygiène du dépôt

- `README` qui dit comment installer, lancer et tester en quelques commandes.
- Ne jamais versionner d'artefacts de build, de dépendances installées, de binaires ni de
  fichiers générés.
- Scripts de développement courants accessibles par une commande unique (`make`, scripts du
  gestionnaire de paquets).

## 7. À vérifier avant de créer un fichier

1. Existe-t-il déjà un endroit prévu pour ça dans le projet ?
2. À quel module métier appartient-il ?
3. Est-ce vraiment partagé, ou propre à une fonctionnalité ?
4. L'import que j'ajoute franchit-il une frontière de module par son API publique ?

---
name: secret-guard-sentinel
description: Analyse le code, les fichiers .env et les configurations pour bloquer toute fuite de secret ou credential.
---

# Règle d'or Zéro-Secret

Lors de la rédaction ou modification de code :
1. **Interdiction Formelle** :
   - Jamais de chaîne ressemblant à une clé d'API, mot de passe de base de données, JWT secret, ou token Bearer directement dans le code source.
2. **Action Immédiate en cas de détection** :
   - Masquer la valeur (ex: `sk-proj-****...`).
   - Insérer la variable dans `.env.example` avec une valeur descriptive d'exemple.
   - Utiliser `process.env.NOM_VARIABLE` ou l'équivalent dans le langage cible.
   - Proposer une commande de révocation/rotation si le secret est déjà commit dans l'historique Git.

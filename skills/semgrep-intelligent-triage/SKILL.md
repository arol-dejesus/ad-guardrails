---
name: semgrep-intelligent-triage
description: Exécute Semgrep via MCP, trie les alertes en éliminant les faux positifs grâce au contexte d'exécution et génère les correctifs.
---

# Workflow de Triage Semgrep & Claude

1. Invoque l'outil MCP `semgrep_scan` avec les règles `p/owasp-top-ten` et `p/cwe-top-25`.
2. Pour chaque alerte renvoyée :
   - Vérifie si l'entrée utilisateur est déjà assainie en amont dans le middleware.
   - Détermine si la fonction est exposée publiquement ou restreinte à un usage interne/admin.
   - Classe l'alerte en :
     * VRAI POSITIF EXPLOITABLE
     * VRAI POSITIF THÉORIQUE (défense en profondeur)
     * FAUX POSITIF (expliquer pourquoi avec preuve dans le flux de code)
3. Rédige un patch unifié pour chaque Vrai Positif.

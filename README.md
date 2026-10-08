<div align="center">

# AD Guardrails

**Des règles que Claude Code applique tout seul, à chaque session, sans qu'on les lui répète.**

[![Stars](https://img.shields.io/github/stars/arol-dejesus/ad-guardrails?style=flat&color=yellow)](https://github.com/arol-dejesus/ad-guardrails/stargazers)
[![Dernier commit](https://img.shields.io/github/last-commit/arol-dejesus/ad-guardrails?color=green)](https://github.com/arol-dejesus/ad-guardrails/commits/main)
![Plugin Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)
![Skills](https://img.shields.io/badge/skills-12-blue)
![Agents](https://img.shields.io/badge/agents-4-blue)
![Hooks](https://img.shields.io/badge/hooks-3-blue)

![Sécurité](https://img.shields.io/badge/s%C3%A9curit%C3%A9-OWASP%20Top%2010-critical)
![Architecture](https://img.shields.io/badge/architecture-monolithe%20modulaire-8250df)
![Performance](https://img.shields.io/badge/performance-10%20000%20utilisateurs-success)
![Audit](https://img.shields.io/badge/audit-gitleaks%20%C2%B7%20semgrep%20%C2%B7%20trivy-informational)

</div>

---

## Le problème

Claude Code écrit du code vite, mais il ne se souvient de rien d'une session à l'autre. Les
consignes de sécurité, d'architecture ou de performance données lundi sont oubliées mardi. Il
faut les répéter dans chaque projet, et dès qu'on oublie de le faire :

- un secret se retrouve en dur dans le code, ou une requête SQL est construite par concaténation ;
- un fichier atterrit au mauvais endroit, la logique métier se mélange au framework ;
- une liste sans pagination fonctionne avec 20 lignes en développement et s'effondre en production ;
- le modèle le plus cher fait lui-même les tâches les plus simples, et les tokens partent vite.

## À quoi ça sert

Ce dépôt installe une fois pour toutes un socle de règles que Claude Code reçoit
**automatiquement** dans chaque session et chaque projet, ancien ou nouveau :

| Règle | Ce que Claude fait sans qu'on le demande |
|---|---|
| **1. Sécurité** | Écrit du code conforme à OWASP Top 10 / ASVS, sans secret en dur, avec une cryptographie et une authentification correctes, et vérifie les dépendances |
| **2. Architecture, structure, backend** | Respecte la structure du projet, isole le métier de l'infrastructure, valide les entrées, gère les erreurs, les timeouts, les migrations et les tests |
| **3. Performance** | Écrit chaque requête, liste et écran pour tenir au moins 10 000 utilisateurs |
| **4. Délégation** | Confie l'exécution à des agents spécialisés et choisit le modèle selon la difficulté, pour dépenser moins de tokens |

## Pourquoi ça marche

Une consigne écrite dans un fichier dépend de la mémoire du modèle. Ici, les règles sont
**réinjectées par des scripts**, qui tournent que Claude s'en souvienne ou non :

```
Début de session  ──▶  résumé des 4 règles injecté dans le contexte
Tous les 20 messages ─▶  le même résumé, pour les longues sessions
Avant chaque fichier écrit ─▶  rappel de sécurité + rappel architecture / backend / performance
Avant chaque git push ─▶  audit : secrets (gitleaks), code (semgrep), dépendances (trivy)
Sur GitHub  ──▶  le même audit en CI, avec une issue « Audit de sécurité » si besoin
```

Trois niveaux se complètent : les **règles** disent quoi faire, les **hooks** les rappellent
au bon moment, et les **analyses automatiques** vérifient le résultat.

## Installation rapide

Dans Claude Code :

```text
/plugin marketplace add arol-dejesus/ad-guardrails
/plugin install ad-guardrails@ad-guardrails
```

Puis dans un terminal :

```bash
git clone https://github.com/arol-dejesus/ad-guardrails.git
bash ad-guardrails/scripts/install-extras.sh
```

Relancer Claude Code : c'est actif partout. Le détail de chaque étape est dans la section
[Installation détaillée](#installation-détaillée).

## Contenu

| Élément | Détail |
|---|---|
| 12 skills | `owasp-security-audit`, `secret-guard-sentinel`, `crypto-auth-auditor`, `supply-chain-auditor`, `stride-threat-modeler`, `semgrep-intelligent-triage`, `multi-stage-vulnerability-verifier`, `claude-agent-hardening`, `backend-architecture-rules`, `project-structure-rules`, `backend-dev-rules`, `performance-rules` |
| 4 agents | `software-architect` (Opus), `database-engineer` (Sonnet), `flutter-mobile-developer` (Sonnet), `quick-task` (Haiku) |
| 3 hooks Claude Code | résumé des règles au début de chaque session et tous les 20 messages ; rappel de sécurité et rappel architecture/backend/performance avant chaque écriture de code |
| Hook git `pre-push` | audit de sécurité de chaque push : secrets (gitleaks), code (semgrep), dépendances (trivy) |
| Workflow GitHub Actions | le même audit côté GitHub, avec rapport dans le run et issue « Audit de sécurité » |
| Règles `CLAUDE.md` | le texte complet des règles n°1 à 4, à placer dans `~/.claude/CLAUDE.md` |

## Installation détaillée

### 1. Le plugin (skills, agents, hooks Claude Code)

Dans Claude Code :

```text
/plugin marketplace add arol-dejesus/ad-guardrails
/plugin install ad-guardrails@ad-guardrails
```

Puis relancer Claude Code.

### 2. Le reste (règles `CLAUDE.md`, hook git, modèle de workflow)

Un plugin ne peut ni écrire dans `~/.claude/CLAUDE.md` ni installer un hook git. Un script le fait :

```bash
git clone https://github.com/arol-dejesus/ad-guardrails.git
bash ad-guardrails/scripts/install-extras.sh
```

Le script :

- écrit les règles dans `~/.claude/CLAUDE.md` entre deux marqueurs (une sauvegarde est faite ;
  le relancer met à jour le bloc sans toucher au reste du fichier) ;
- installe le hook git global dans `~/.config/git/hooks` et règle `core.hooksPath` ;
- copie le modèle de workflow dans `~/.config/git/security-kit/security.yml`.

Options : `--no-git-hook` pour ne pas toucher à git, `--force` pour remplacer un
`core.hooksPath` global déjà défini ailleurs.

Outils attendus par le hook git : `gitleaks`, `semgrep`, `trivy`. Le script signale ceux qui
manquent et ne les installe pas ; une analyse dont l'outil est absent est sautée.

### 3. Le workflow dans un dépôt

```bash
mkdir -p .github/workflows
cp ~/.config/git/security-kit/security.yml .github/workflows/security.yml
```

## Fonctionnement

### Rappels dans Claude Code

- **Début de session, reprise, compaction** : un résumé des quatre règles est injecté.
- **Premier message d'une session, puis tous les 20 messages** : le même résumé, pour les
  sessions longues ou ouvertes avant l'installation.
- **Avant chaque écriture d'un fichier de code** : rappel de sécurité à chaque fois ; rappel
  architecture/backend/performance complet au premier fichier de la session et à chaque
  création de fichier, puis en une ligne. La documentation est ignorée.

Désactiver un rappel : `STANDING_RULES_DISABLE=1`, `SECURITY_REMINDER_DISABLE=1`,
`ENGINEERING_REMINDER_DISABLE=1`.

### Audit à chaque push

Le hook git est en **mode audit** : il affiche les failles trouvées, enregistre le rapport dans
`~/.local/state/security-audits/` et laisse passer le push.

- Refuser le push en cas de faille : `SECURITY_ENFORCE=1 git push`
- Sauter l'audit une fois : `SECURITY_SKIP=1 git push`

L'audit lit les fichiers tels qu'ils sont dans le commit poussé, pas dans le dossier de travail.
Le dépôt analysé ne peut pas le faire taire : sa propre configuration des scanners et ses
exclusions (`.gitleaks.toml`, `.gitleaksignore`, `.semgrepignore`, commentaires `nosemgrep`,
`.trivyignore`, `trivy.yaml`) sont ignorées, et les dossiers de tests sont analysés aussi.
Pour les prendre en compte : `SECURITY_TRUST_REPO_CONFIG=1 git push`. Les rapports citent les
lignes de code signalées : ils ne sont lisibles que par ton compte.

Comme `core.hooksPath` global fait ignorer à git les hooks propres à chaque dépôt, des relais
les exécutent quand ils existent.

### Délégation aux agents

| Difficulté | Modèle | Agents |
|---|---|---|
| Simple, mécanique | Haiku | `quick-task`, `Explore` |
| Implémentation standard | Sonnet | `database-engineer`, `flutter-mobile-developer` et les agents de développement déjà installés |
| Architecture, revue, sécurité | Opus | `software-architect` et les agents de revue et d'audit déjà installés |

La table complète, par type de tâche, est dans `templates/CLAUDE.rules.md`. Elle cite aussi des
agents et des skills qui ne font pas partie de ce dépôt (`backend-developer`, `code-reviewer`,
`flutter-expert`, `postgres-pro`…) : s'ils ne sont pas installés, Claude utilise un agent
généraliste à la place.

## Limites

- **Ce sont des rappels et des contrôles, pas une garantie.** Les hooks assurent que les règles
  sont présentées à Claude à chaque fois ; ils ne prouvent pas que le code produit est sans
  défaut. Les analyses automatiques ne détectent que les secrets, les failles et les CVE connus.
- **La tenue à 10 000 utilisateurs ne se prouve que par un test de charge** sur l'application réelle.
- **L'économie de tokens dépend des tâches.** Déléguer une petite tâche coûte plus cher que la
  faire ; le gain vient du travail simple confié à un modèle moins cher et des gros volumes lus
  hors du contexte principal. Mesurer avec `/cost`.
- **Une machine à la fois.** Rien ne s'applique à Claude sur le web ou sur mobile.
- **Installation par plugin non testée de bout en bout.** Le contenu a été mis au point et
  vérifié installé directement dans `~/.claude` ; le manifeste du plugin est validé, mais le
  préchargement des skills par les agents du plugin n'a pas été vérifié dans cette forme.

## Origine du contenu

Les huit skills de sécurité reprennent des textes fournis par l'auteur du dépôt. Les skills
d'architecture, de structure, de backend et de performance, les agents, les hooks et le
workflow ont été écrits pour ce dépôt.

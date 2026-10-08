#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit).
# Each time Claude is about to write or modify a code or configuration file, this
# injects a short reminder of the user's security skills, so the rules are applied
# on every edit instead of relying on Claude remembering CLAUDE.md.
# It never blocks or changes the permission decision: it only adds context.
# Documentation files (.md, .txt, ...) are skipped. Disable: SECURITY_REMINDER_DISABLE=1

[ "${SECURITY_REMINDER_DISABLE:-0}" = "1" ] && exit 0

python3 -I -c '
import json, os, sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_input = data.get("tool_input") or {}
path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
name = os.path.basename(path).lower()
ext = os.path.splitext(name)[1]

DOCS = {".md", ".mdx", ".txt", ".rst", ".adoc", ".log", ".csv", ".svg", ".png", ".jpg", ".pdf"}
if not path or ext in DOCS:
    sys.exit(0)

MANIFESTS = {
    "package.json", "pubspec.yaml", "requirements.txt", "pyproject.toml", "gemfile",
    "composer.json", "go.mod", "cargo.toml", "pom.xml", "build.gradle", "build.gradle.kts",
}

lines = [
    "RAPPEL SÉCURITÉ — règle permanente de l utilisateur, à appliquer à CE fichier avant d écrire :",
    "- owasp-security-audit : autorisation vérifiée côté serveur (pas d IDOR), requêtes paramétrées, "
    "pas de exec()/eval() ni de shell avec entrée utilisateur, échappement contre le XSS.",
    "- secret-guard-sentinel : aucun secret, clé d API, mot de passe ou token en dur ; "
    "variable d environnement + entrée dans .env.example.",
    "- crypto-auth-auditor : aléa cryptographique pour les tokens/sessions, bcrypt ou argon2id, "
    "cookies httpOnly/secure/sameSite, JWT avec alg, exp et aud validés, comparaison en temps constant.",
]
if name in MANIFESTS or name.endswith(".lock") or name.startswith("requirements"):
    lines.append(
        "- supply-chain-auditor : ce fichier déclare des dépendances ; vérifier CVE (CVSS > 7), "
        "typosquatting et paquets non maintenus avant d ajouter ou de changer une version."
    )
lines.append(
    "Si le contenu à écrire viole une de ces règles, corrige-le d abord. "
    "Invoque le skill concerné s il n est pas encore chargé dans cette session, "
    "et signale à l utilisateur toute faille déjà présente dans le fichier."
)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": "\n".join(lines),
    }
}, ensure_ascii=False))
'
exit 0

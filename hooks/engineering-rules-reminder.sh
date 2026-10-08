#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit).
# Reminds Claude of the user's architecture, project-structure, backend-development and
# performance rules (target: at least 10,000 users) each time it is about to write a source-code file, so they are applied on every
# edit instead of relying on Claude remembering CLAUDE.md.
#   - full reminder: first code edit of a session, and every time a NEW file is created
#     (that is when structure and architecture decisions are made)
#   - one-line reminder: every other code edit
# It never blocks or changes the permission decision: it only adds context.
# Docs, styles and plain config files are skipped. Disable: ENGINEERING_REMINDER_DISABLE=1

[ "${ENGINEERING_REMINDER_DISABLE:-0}" = "1" ] && exit 0

python3 -I -c '
import json, os, re, sys, time

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_input = data.get("tool_input") or {}
path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
name = os.path.basename(path).lower()
ext = os.path.splitext(name)[1]

SKIP = {
    ".md", ".mdx", ".txt", ".rst", ".adoc", ".log", ".csv", ".svg", ".png", ".jpg", ".pdf",
    ".css", ".scss", ".sass", ".less", ".html", ".htm",
    ".json", ".yaml", ".yml", ".toml", ".ini", ".env", ".lock", ".xml", ".properties",
}
if not path or not ext or ext in SKIP or name.startswith(".env"):
    sys.exit(0)

# One marker per session, so the full reminder is given once, then only on new files.
session = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id") or "nosession"))[:80]
state_dir = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "claude-engineering-reminder"
)
marker = os.path.join(state_dir, session)
first_in_session = not os.path.exists(marker)
try:
    os.makedirs(state_dir, exist_ok=True)
    if first_in_session:
        open(marker, "w").close()
        # Drop markers older than 7 days.
        limit = time.time() - 7 * 86400
        for f in os.listdir(state_dir):
            p = os.path.join(state_dir, f)
            if os.path.isfile(p) and os.path.getmtime(p) < limit:
                os.remove(p)
except OSError:
    pass

new_file = data.get("tool_name") == "Write" and not os.path.exists(path)

if first_in_session or new_file:
    lines = [
        "RAPPEL ARCHITECTURE / STRUCTURE / BACKEND / PERFORMANCE — règle permanente de l utilisateur :",
        "- backend-architecture-rules : monolithe modulaire d abord ; logique métier sans dépendance "
        "au framework ni à la base (dépendances vers l intérieur) ; un module n importe que l API "
        "publique d un autre ; contrôleurs minces ; décision structurante = ADR.",
        "- project-structure-rules : respecter la structure existante du projet ; ranger par "
        "fonctionnalité/domaine, pas par couche technique ; pas de fourre-tout utils/helpers ; "
        "un fichier = une responsabilité ; configuration centralisée et validée.",
        "- backend-dev-rules : entrées validées à la frontière ; erreurs RFC 9457 ; listes paginées "
        "et bornées ; opérations rejouables idempotentes ; timeout sur tout appel sortant ; pas de "
        "N+1 ; migrations compatibles (expand/contract) ; logs structurés et traces ; tests écrits.",
        "- performance-rules : viser AU MOINS 10 000 utilisateurs ; écrire chaque requête, liste et "
        "boucle comme si la table avait des millions de lignes ; requêtes sur index et bornées ; "
        "pool de connexions ; cache avec invalidation ; travail long en file de tâches ; API p95 "
        "<= 200 ms en lecture ; web LCP <= 2,5 s et INP <= 200 ms ; mobile 60 images/s ; ne pas "
        "affirmer une tenue en charge sans mesure.",
    ]
    if new_file:
        lines.append(
            "Tu crées un NOUVEAU fichier : vérifie d abord qu il est au bon endroit "
            "(quel module métier ? existe-t-il déjà un emplacement prévu ?)."
        )
    lines.append(
        "Invoque le skill concerné s il n est pas encore chargé dans cette session. "
        "Architecture et backend visent le code serveur ; la performance vaut pour tout code "
        "(serveur, web, mobile). Pour un script ponctuel, n en garde que ce qui a du sens."
    )
else:
    lines = [
        "Rappel : respecter backend-architecture-rules, project-structure-rules, backend-dev-rules et "
        "performance-rules (frontières de modules, validation des entrées, erreurs RFC 9457, timeouts, "
        "pas de N+1, requêtes sur index et bornées, cible 10 000 utilisateurs, tests)."
    ]

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": "\n".join(lines),
    }
}, ensure_ascii=False))
'
exit 0

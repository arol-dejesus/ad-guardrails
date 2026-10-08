#!/usr/bin/env bash
# Installe ce que le plugin Claude Code ne peut pas installer lui-même :
#   1. les règles permanentes dans ~/.claude/CLAUDE.md (entre deux marqueurs, mise à jour sûre)
#   2. le hook git global pre-push (audit de sécurité à chaque push)
#   3. le modèle de workflow GitHub Actions dans ~/.config/git/security-kit/
# Le script n'installe aucun outil : il indique seulement ceux qui manquent.
#
# Usage : bash scripts/install-extras.sh [--no-git-hook] [--force]
#   --no-git-hook  n'installe pas le hook git global
#   --force        remplace un core.hooksPath global déjà défini ailleurs

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
git_hook=1
force=0
for arg in "$@"; do
  case "$arg" in
    --no-git-hook) git_hook=0 ;;
    --force) force=1 ;;
    *) echo "Option inconnue : $arg" >&2; exit 2 ;;
  esac
done

# --- 1. Règles dans ~/.claude/CLAUDE.md -------------------------------------------------
claude_md="$HOME/.claude/CLAUDE.md"
begin="<!-- ad-guardrails:begin -->"
end="<!-- ad-guardrails:end -->"
mkdir -p "$HOME/.claude"
touch "$claude_md"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
if grep -qF "$begin" "$claude_md"; then
  # Remplace le bloc existant, garde tout le reste du fichier.
  awk -v b="$begin" -v e="$end" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip { print }
  ' "$claude_md" >"$tmp"
else
  cp "$claude_md" "$tmp"
fi
{
  cat "$tmp"
  echo
  echo "$begin"
  cat "$here/templates/CLAUDE.rules.md"
  echo "$end"
} >"$claude_md.new"
cp -p "$claude_md" "$claude_md.bak-guardrails"
mv "$claude_md.new" "$claude_md"
echo "✓ Règles écrites dans $claude_md (sauvegarde : $claude_md.bak-guardrails)"

# --- 2. Hook git global ------------------------------------------------------------------
if [ "$git_hook" = "1" ]; then
  target="$HOME/.config/git/hooks"
  current="$(git config --global --get core.hooksPath || true)"
  if [ -n "$current" ] && [ "$current" != "$target" ] && [ "$force" != "1" ]; then
    echo "⚠ core.hooksPath global vaut déjà « $current » : hook git non installé." >&2
    echo "  Relance avec --force pour le remplacer, ou --no-git-hook pour l'ignorer." >&2
  else
    if [ -n "$current" ] && [ "$current" != "$target" ]; then
      echo "⚠ core.hooksPath global passe de « $current » à « $target »." >&2
      echo "  Les hooks qui se trouvaient dans « $current » ne seront plus exécutés." >&2
    fi
    mkdir -p "$target"
    install -m 755 "$here/git-hooks/pre-push" "$here/git-hooks/_chain" "$target/"
    # Avec core.hooksPath, git ignore les hooks propres à chaque dépôt : ces liens les relaient.
    for name in applypatch-msg pre-applypatch post-applypatch pre-commit pre-merge-commit \
      prepare-commit-msg commit-msg post-commit pre-rebase post-checkout post-merge \
      post-rewrite pre-auto-gc reference-transaction post-index-change sendemail-validate \
      push-to-checkout pre-receive update proc-receive post-receive post-update; do
      ln -sf _chain "$target/$name"
    done
    git config --global core.hooksPath "$target"
    echo "✓ Hook git global installé dans $target (mode audit, non bloquant)"
    echo "  Les hooks propres à chaque dépôt (.git/hooks) restent exécutés par relais."
    echo "  Un dépôt qui définit son propre core.hooksPath (husky, par exemple) n'exécute pas"
    echo "  ce hook global : l'audit y est alors à ajouter dans les hooks du dépôt."
    echo "  Bloquer un push : SECURITY_ENFORCE=1 git push — sauter l'audit : SECURITY_SKIP=1 git push"
  fi
fi

# --- 3. Modèle de workflow ---------------------------------------------------------------
kit="$HOME/.config/git/security-kit"
mkdir -p "$kit"
install -m 644 "$here/templates/security.yml" "$kit/security.yml"
echo "✓ Modèle de workflow copié dans $kit/security.yml"
echo "  À placer dans .github/workflows/security.yml de chaque dépôt."

# --- Outils attendus par le hook git -------------------------------------------------------
missing=""
for tool in gitleaks semgrep trivy; do
  command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
done
if [ -n "$missing" ]; then
  echo "⚠ Outils absents :$missing — le hook git saute les analyses correspondantes."
  echo "  gitleaks : https://github.com/gitleaks/gitleaks/releases"
  echo "  semgrep  : pipx install semgrep"
  echo "  trivy    : https://github.com/aquasecurity/trivy/releases"
fi

echo "Terminé. Relance Claude Code pour charger les règles."

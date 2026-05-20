#!/usr/bin/env bash
# Symlink every skill and command in this repo into ~/.claude/.
# Idempotent. Refuses to run if ~/.claude/skills or ~/.claude/commands
# is a whole-directory symlink (legacy install) — convert it first:
#
#   rm ~/.claude/skills ~/.claude/commands
#   mkdir ~/.claude/skills ~/.claude/commands
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

install_items() {
  local kind="$1"  # skills | commands
  local src="${REPO_DIR}/${kind}"
  local dst="${CLAUDE_DIR}/${kind}"

  [[ -d "$src" ]] || { echo "no ${kind}/ in repo, skipping"; return; }

  if [[ -L "$dst" ]]; then
    echo "ERROR: ${dst} is a symlink (legacy whole-dir install)."
    echo "       Remove it and create a real directory, then re-run:"
    echo "           rm ${dst} && mkdir ${dst}"
    exit 1
  fi

  mkdir -p "$dst"

  for item in "$src"/*; do
    [[ -e "$item" ]] || continue
    local name target current
    name="$(basename "$item")"
    target="${dst}/${name}"

    if [[ -L "$target" ]]; then
      current="$(readlink "$target")"
      if [[ "$current" == "$item" ]]; then
        echo "ok    ${kind}/${name}"
        continue
      fi
      echo "WARN  ${kind}/${name} -> ${current} (replacing)"
      rm "$target"
    elif [[ -e "$target" ]]; then
      echo "SKIP  ${kind}/${name} (real file/dir exists, not touching)"
      continue
    fi

    ln -s "$item" "$target"
    echo "link  ${kind}/${name}"
  done
}

install_items skills
install_items commands

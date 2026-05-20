#!/usr/bin/env bash
# Symlink skills and commands from this repo into ~/.claude/.
#
# Usage:
#   ./install.sh                  # install every skill and command
#   ./install.sh NAME [NAME ...]  # install only the named items
#                                 # each NAME is matched against skills/ then commands/
#   ./install.sh -l, --list       # list available items and exit
#   ./install.sh -h, --help       # show this help
#
# Idempotent.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

usage() {
  sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

list_items() {
  local kind
  for kind in skills commands; do
    local src="${REPO_DIR}/${kind}"
    [[ -d "$src" ]] || continue
    echo "${kind}:"
    for item in "$src"/*; do
      [[ -e "$item" ]] || continue
      local name
      name="$(basename "$item")"
      echo "  ${name%.md}"
    done
  done
}

# Ensure ~/.claude/<kind> exists as a real directory. Refuse to install
# per-item symlinks into a directory that is itself a symlink — doing so
# would write inside the symlink target.
ensure_dst_dir() {
  local kind="$1"
  local dst="${CLAUDE_DIR}/${kind}"
  if [[ -L "$dst" ]]; then
    echo "ERROR: ${dst} is a symlink, not a real directory." >&2
    echo "       Replace it before installing:" >&2
    echo "           rm ${dst} && mkdir ${dst}" >&2
    exit 1
  fi
  mkdir -p "$dst"
}

# Symlink a single source path into ~/.claude/<kind>/<name>.
link_one() {
  local kind="$1" item="$2"
  local name target current
  name="$(basename "$item")"
  target="${CLAUDE_DIR}/${kind}/${name}"

  if [[ -L "$target" ]]; then
    current="$(readlink "$target")"
    if [[ "$current" == "$item" ]]; then
      echo "ok    ${kind}/${name}"
      return
    fi
    echo "WARN  ${kind}/${name} -> ${current} (replacing)"
    rm "$target"
  elif [[ -e "$target" ]]; then
    echo "SKIP  ${kind}/${name} (real file/dir exists, not touching)"
    return
  fi

  ln -s "$item" "$target"
  echo "link  ${kind}/${name}"
}

install_all_of() {
  local kind="$1"
  local src="${REPO_DIR}/${kind}"
  [[ -d "$src" ]] || { echo "no ${kind}/ in repo, skipping"; return; }
  ensure_dst_dir "$kind"
  for item in "$src"/*; do
    [[ -e "$item" ]] || continue
    link_one "$kind" "$item"
  done
}

# Find an item by bare name in skills/ then commands/. Echoes "<kind>\t<path>" on hit.
resolve_name() {
  local name="$1" kind src match
  for kind in skills commands; do
    src="${REPO_DIR}/${kind}"
    [[ -d "$src" ]] || continue
    # Match either "foo" (skill dir) or "foo" / "foo.md" (command file).
    for match in "${src}/${name}" "${src}/${name}.md"; do
      if [[ -e "$match" ]]; then
        printf '%s\t%s\n' "$kind" "$match"
        return 0
      fi
    done
  done
  return 1
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -l|--list) list_items; exit 0 ;;
esac

if [[ $# -eq 0 ]]; then
  install_all_of skills
  install_all_of commands
  exit 0
fi

# Resolve every name first so we fail before making any changes on a typo.
declare -a resolved=()
missing=0
for name in "$@"; do
  if hit="$(resolve_name "$name")"; then
    resolved+=("$hit")
  else
    echo "ERROR: no skill or command named '${name}'" >&2
    missing=1
  fi
done
if [[ $missing -ne 0 ]]; then
  echo "       run './install.sh --list' to see available items" >&2
  exit 1
fi

declare -A ensured=()
for entry in "${resolved[@]}"; do
  kind="${entry%%$'\t'*}"
  path="${entry#*$'\t'}"
  if [[ -z "${ensured[$kind]:-}" ]]; then
    ensure_dst_dir "$kind"
    ensured[$kind]=1
  fi
  link_one "$kind" "$path"
done

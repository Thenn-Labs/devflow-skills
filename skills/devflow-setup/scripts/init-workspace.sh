#!/usr/bin/env bash
# Creates the workspace files in a project from the devflow-setup skill templates.
# Never overwrites an existing file. If CLAUDE.md exists, appends the
# workspace section once (detected by its marker comment).
# Usage: init-workspace.sh [project_dir]
set -euo pipefail

project="${1:-$PWD}"
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
templates="$skill_dir/templates"
today="$(date +%Y-%m-%d)"
marker="<!-- devflow:start -->"

if [ ! -d "$project" ]; then
  echo "Project directory not found: $project" >&2
  exit 1
fi

files=(context.md progress.md agents.md AgentQuestions.md AgentAnswers.md role.md tasks.md report.md)

# CLAUDE.md: create, or append the workspace section once.
claude="$project/CLAUDE.md"
if [ ! -f "$claude" ]; then
  { echo "# CLAUDE.md"; echo; cat "$templates/CLAUDE.md"; } > "$claude"
  echo "created   CLAUDE.md"
elif grep -qF "$marker" "$claude"; then
  echo "exists    CLAUDE.md (workspace section already present)"
else
  { echo; cat "$templates/CLAUDE.md"; } >> "$claude"
  echo "appended  CLAUDE.md (added workspace section)"
fi

for f in "${files[@]}"; do
  target="$project/$f"
  # Case-insensitive match, so e.g. an existing AGENTS.md or Progress.md is not duplicated.
  existing="$(find "$project" -maxdepth 1 -iname "$f" -print -quit)"
  if [ -n "$existing" ]; then
    echo "exists    $(basename "$existing") (left unchanged)"
  else
    sed "s/{{DATE}}/$today/g" "$templates/$f" > "$target"
    echo "created   $f"
  fi
done

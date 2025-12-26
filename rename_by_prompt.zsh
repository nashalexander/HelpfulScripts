#!/usr/bin/env zsh
# Usage: ./rename_by_prompt.zsh [-n|--dry-run] <directory> <extension>
# Example: ./rename_by_prompt.zsh -n /path/to/dir mp3

set -u


dry_run=0
if [[ "${1:-}" == "-n" || "${1:-}" == "--dry-run" ]]; then
  dry_run=1
  shift
fi

dir="${1:-.}"
ext="${2:-}"

if [[ -z "$ext" ]]; then
  print -r -- "Usage: $0 [-n|--dry-run] <directory> <extension>"
  exit 1
fi

if [[ ! -d "$dir" ]]; then
  print -r -- "Error: directory not found: $dir"
  exit 1
fi

# Normalize extension (strip leading dot if provided)
ext="${ext#.}"

# Find files matching the extension (non-recursive).
# Read user input from /dev/tty so prompts don't consume filenames.
while IFS= read -r -d '' file; do
  base="${file:t}"         # filename.ext
  name="${base:r}"          # filename
  suffix="${base:e}"        # ext

  print -r -- ""
  print -r -- "File: $base"
  newname="$name"
  vared -p "Edit name (without .${suffix}), or leave blank to skip: " newname < /dev/tty

  if [[ -z "$newname" ]]; then
    print -r -- "Skipped."
  elif [[ "$newname" == "$name" ]]; then
    print -r -- "Kept: $base"
  else
    newpath="${file:h}/${newname}.${suffix}"
    if [[ -e "$newpath" ]]; then
      print -r -- "Skipped: target exists: $newpath"
    else
      if [[ "$dry_run" -eq 1 ]]; then
        print -r -- "Would rename to: ${newname}.${suffix}"
      else
        mv -- "$file" "$newpath"
        print -r -- "Renamed to: ${newname}.${suffix}"
      fi
    fi
  fi
done < <(find "$dir" -maxdepth 1 -type f -name "*.${ext}" -print0)

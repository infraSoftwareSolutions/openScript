#!/usr/bin/env bash
set -euo pipefail

# Simple bash equivalents for counting utilities from count.psm1
# Usage examples:
#   ./count.sh count-lines path1 [path2 ...]
#   ./count.sh measure path
#   ./count.sh files-by-ext path
#   ./count.sh filesize path
#   ./count.sh smart-count path

resolve_path() {
  local p="$1"
  if [[ "${p:0:1}" = "/" || "$p" =~ ^[A-Za-z]:\\ ]]; then
    echo "$p"
  else
    echo "$(pwd)/$p"
  fi
}

count_lines_file() {
  local f="$1"
  if [[ ! -f "$f" ]]; then echo "0"; return; fi
  local lines
  lines=$(wc -l <"$f" 2>/dev/null || echo 0)
  echo "$lines"
}

count_code_lines() {
  local total=0
  for p in "$@"; do
    local rp; rp=$(resolve_path "$p")
    if [[ -f "$rp" ]]; then
      local l; l=$(count_lines_file "$rp")
      echo "$rp : $l"
      total=$((total + l))
    elif [[ -d "$rp" ]]; then
      while IFS= read -r -d $'\0' file; do
        local l; l=$(count_lines_file "$file")
        echo "$file : $l"
        total=$((total + l))
      done < <(find "$rp" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.ps1" -o -name "*.psm1" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) -print0)
    else
      echo "Path not found: $rp" >&2
    fi
  done
  echo "Total lines: $total"
}

measure_code_lines() {
  local p; p=$(resolve_path "$1")
  if [[ -f "$p" ]]; then
    wc -l <"$p"
  else
    find "$p" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.ps1" -o -name "*.psm1" -o -name "*.py" \) -exec cat {} + | wc -l
  fi
}

files_by_extension() {
  local p; p=$(resolve_path "$1")
  find "$p" -type f | sed -n 's/.*\.\([^.]*\)$/\1/p' | sort | uniq -c | sort -rn
}

filesize_total() {
  local p; p=$(resolve_path "$1")
  if [[ -f "$p" ]]; then du -h "$p" | cut -f1
  else du -sh "$p" | cut -f1
  fi
}

# naive smart count: removes blank lines and simple single-line comments
smart_count_file() {
  local file="$1"
  local ext; ext=${file##*.}
  case "$ext" in
    py|sh|bash|ps1|psm1)
      grep -vE "^\s*(#|$)" "$file" | wc -l
      ;;
    c|cpp|h|hpp)
      # remove /* */ blocks crudely and lines starting with //
      sed -e ':a' -e '/\/\*/,/\*\//{ /\*\//!{N;ba}; s/\/\*.*?\*\///g }' "$file" 2>/dev/null | grep -vE "^\s*(//|/\*|\*|$)" | wc -l
      ;;
    *)
      grep -vE "^\s*(//|#|$)" "$file" | wc -l
      ;;
  esac
}

smart_count() {
  local total=0
  local p; p=$(resolve_path "$1")
  if [[ -f "$p" ]]; then
    local l; l=$(smart_count_file "$p")
    echo "$p : $l"
    total=$((total + l))
  else
    while IFS= read -r -d $'\0' file; do
      local l; l=$(smart_count_file "$file")
      echo "$file : $l"
      total=$((total + l))
    done < <(find "$p" -type f -print0)
  fi
  echo "Total effective lines: $total"
}

# CLI dispatch
if [[ $# -lt 2 ]]; then
  cat <<EOF
Usage: $0 <command> <path...>
Commands:
  count-lines <paths...>
  measure <path>
  files-by-ext <path>
  filesize <path>
  smart-count <path>
EOF
  exit 1
fi

cmd="$1"; shift
case "$cmd" in
  count-lines) count_code_lines "$@";
  ;;
  measure) measure_code_lines "$1";
  ;;
  files-by-ext) files_by_extension "$1";
  ;;
  filesize) filesize_total "$1";
  ;;
  smart-count) smart_count "$1";
  ;;
  *) echo "Unknown command: $cmd"; exit 2;;
esac

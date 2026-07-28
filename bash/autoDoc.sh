#!/usr/bin/env bash
set -euo pipefail

# Simple bash equivalent of Invoke-AutoDoc (PowerShell)
# Usage: ./autoDoc.sh --path <path> [--format txt|md|doxygen|all] [--outdir <dir>] [--recurse] [--force]

OLLAMA_MODEL="llama3.2:1b"

set_ollama_model() {
  OLLAMA_MODEL="$1"
  echo "Ollama model set to: $OLLAMA_MODEL"
}

_detect_ollama() {
  if ! command -v ollama >/dev/null 2>&1; then
    echo "Error: ollama not found in PATH." >&2
    return 1
  fi
  return 0
}

_pull_model_if_missing() {
  local m="$1"
  if ! ollama list | grep -Fq "$m"; then
    echo "Model '$m' not present locally — pulling..."
    ollama pull "$m"
  fi
}

# generate documentation for a single file
_document_file() {
  local file="$1"; local format="$2"; local outdir="$3"; local force="$4"
  local fname; fname=$(basename "$file")
  local name; name=${fname%.*}
  mkdir -p "$outdir"
  local code; code=$(<"$file")

  if [[ "$format" == "doxygen" || "$format" == "all" ]]; then
    local prompt
    prompt="Add Doxygen-style comments to the following code.\nLanguage: auto\nCode:\n$code"
    local out; out=$(printf "%s" "$prompt" | ollama run "$OLLAMA_MODEL")
    local target="$outdir/${name}${fname##*.}"
    if [[ "$force" == "true" || ! -e "$target" ]]; then
      printf "%s" "$out" >"$target"
      echo "  -> Doxygen: $target"
    else
      echo "  -> Doxygen exists: $target"
    fi
  fi

  if [[ "$format" == "md" || "$format" == "all" ]]; then
    local prompt
    prompt="Generate professional Markdown documentation for the following code.\nLanguage: auto\nCode:\n$code"
    local out; out=$(printf "%s" "$prompt" | ollama run "$OLLAMA_MODEL")
    local target="$outdir/${name}.md"
    if [[ "$force" == "true" || ! -e "$target" ]]; then
      printf "%s" "$out" >"$target"
      echo "  -> Markdown: $target"
    else
      echo "  -> Markdown exists: $target"
    fi
  fi

  if [[ "$format" == "txt" || "$format" == "all" ]]; then
    local prompt
    prompt="Generate plain text documentation for the following code.\nLanguage: auto\nCode:\n$code"
    local out; out=$(printf "%s" "$prompt" | ollama run "$OLLAMA_MODEL")
    local target="$outdir/${name}.txt"
    if [[ "$force" == "true" || ! -e "$target" ]]; then
      printf "%s" "$out" >"$target"
      echo "  -> Text: $target"
    else
      echo "  -> Text exists: $target"
    fi
  fi
}

usage() {
  cat <<EOF
Usage: $0 --path <file|dir> [--format txt|md|doxygen|all] [--outdir <dir>] [--recurse] [--force] [--model <name>]
EOF
}

# argument parsing
PATH_ARG=""
FORMAT="doxygen"
OUTDIR="Documentation"
RECURSE=false
FORCE=false
EXTENSIONS=(.cpp .c .h .hpp .java .ps1 .psm1 .py .cs .js .ts .bash .sh)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path|-p) PATH_ARG="$2"; shift 2;;
    --format) FORMAT="$2"; shift 2;;
    --outdir) OUTDIR="$2"; shift 2;;
    --recurse) RECURSE=true; shift 1;;
    --force) FORCE=true; shift 1;;
    --model) set_ollama_model "$2"; shift 2;;
    --help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$PATH_ARG" ]]; then
  usage; exit 1
fi

if ! _detect_ollama; then exit 1; fi
_pull_model_if_missing "$OLLAMA_MODEL"

if [[ ! -e "$PATH_ARG" ]]; then
  echo "Path not found: $PATH_ARG" >&2; exit 1
fi

if [[ -f "$PATH_ARG" ]]; then
  _document_file "$PATH_ARG" "$FORMAT" "$OUTDIR" "$FORCE"
  exit 0
fi

# directory
shopt -s globstar nullglob
files=()
if [[ "$RECURSE" == true ]]; then
  for ext in "${EXTENSIONS[@]}"; do
    for f in "$PATH_ARG"/**/*"$ext"; do
      [[ -f "$f" ]] && files+=("$f")
    done
  done
else
  for ext in "${EXTENSIONS[@]}"; do
    for f in "$PATH_ARG"/*"$ext"; do
      [[ -f "$f" ]] && files+=("$f")
    done
  done
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No matching files found in $PATH_ARG"; exit 0
fi

for f in "${files[@]}"; do
  echo "Processing: $(basename "$f")"
  _document_file "$f" "$FORMAT" "$OUTDIR" "$FORCE"
done

echo "\n✅ Documentation completed. Output saved to: $OUTDIR"
#!/usr/bin/env bash
set -euo pipefail

# Simple bash equivalent of New-Test (PowerShell)
# Usage: ./test.sh --docs docs.txt --lib lib.c --language C --framework GTest [--out outfile] [--ai http://localhost:11434/api/generate] [--model llama2]

AI_ENDPOINT="http://localhost:11434/api/generate"
MODEL="llama2"

usage() {
  cat <<EOF
Usage: $0 --docs <docs> --lib <lib> --language <lang> --framework <framework> [--out <outfile>] [--ai <endpoint>] [--model <model>]
EOF
}

DOCS=""; LIB=""; OUT=""; LANG=""; FRAMEWORK=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs) DOCS="$2"; shift 2;;
    --lib) LIB="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --ai) AI_ENDPOINT="$2"; shift 2;;
    --model) MODEL="$2"; shift 2;;
    --language) LANG="$2"; shift 2;;
    --framework) FRAMEWORK="$2"; shift 2;;
    --help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$DOCS" || -z "$LIB" || -z "$LANG" || -z "$FRAMEWORK" ]]; then
  usage; exit 1
fi

if [[ ! -f "$DOCS" ]]; then echo "Docs file not found: $DOCS" >&2; exit 1; fi
if [[ ! -f "$LIB" ]]; then echo "Lib file not found: $LIB" >&2; exit 1; fi

DOC_TEXT=$(<"$DOCS")
LIB_TEXT=$(<"$LIB")

# Minimal system and user prompts
read -r -d '' SYS_PROMPT <<'SYS'
You are an expert test engineer. Generate production-quality, comprehensive test cases. Output only test code, no explanations.
SYS

read -r -d '' USER_PROMPT <<USER
Framework: ${FRAMEWORK}
Language: ${LANG}

=== DOCUMENTATION ===
${DOC_TEXT}

=== LIBRARY CODE (DO NOT MODIFY) ===
${LIB_TEXT}

TASK: Generate only complete, executable test code following the specified framework syntax.
USER

# Build JSON body
BODY=$(jq -n --arg model "$MODEL" --arg system "$SYS_PROMPT" --arg prompt "$USER_PROMPT" '{model:$model, system:$system, prompt:$prompt, stream:false}')

# Call AI endpoint
RESP=$(curl -s -X POST "$AI_ENDPOINT" -H 'Content-Type: application/json' -d "$BODY" || true)

# Try to extract text from common fields
TESTS=$(echo "$RESP" | jq -r '.response // .choices[0].message.content // .choices[0].text // empty')
if [[ -z "$TESTS" || "$TESTS" == "null" ]]; then
  echo "AI returned unexpected response:" >&2
  echo "$RESP" >&2
  exit 1
fi

if [[ -z "$OUT" ]]; then
  ext=".txt"
  case "$LANG" in
    C) ext='.c' ;; C++) ext='.cpp' ;; Python) ext='.py' ;; PowerShell) ext='.ps1' ;; Java) ext='.java' ;; esac
  OUT="tests_$(date +%Y%m%d_%H%M%S)$ext"
fi

printf "%s" "$TESTS" >"$OUT"

echo "✅ Tests generated and saved to: $OUT"

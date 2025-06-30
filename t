#!/bin/bash

base_prompt="Scrivi solo il codice Python. privilegia l'uso di subprocess. Nessun commento. Nessuna spiegazione. Un solo blocco di codice:"
prompt="$*"
[ -z "$prompt" ] && echo -e "\033[1;31m[!] Prompt mancante\033[0m" && return 1

full_prompt="$base_prompt $prompt"
tmpfile=$(mktemp /tmp/ai_script_XXXX.py)

ollama run llama3.1:8b <<< "$full_prompt" | tee /tmp/ai_response

awk '/```/{p^=1;next}p' /tmp/ai_response > "$tmpfile"
[ ! -s "$tmpfile" ] && awk 'NF' /tmp/ai_response > "$tmpfile"

echo -e "\n\033[1;34m[+] Codice salvato in: $tmpfile\033[0m"
cat "$tmpfile"

while true; do
  read -rp "Eseguire? [Y/n/e] " scelta
  scelta=${scelta,,}
  if [ -z "$scelta" ] || [ "$scelta" = "y" ]; then
    chmod +x "$tmpfile"
    runpy "$tmpfile"
    break
  elif [ "$scelta" = "n" ]; then
    echo "Annullato."
    break
  elif [ "$scelta" = "e" ]; then
    ${EDITOR:-nano} "$tmpfile"
  else
    echo "Scelta non valida."
  fi
done

#!/bin/bash

  base_prompt="Scrivi solo il codice Python. Nessuna dipendenza esterna. Nessun commento. Nessuna spiegazione. Un solo blocco di codice:"
  prompt="$*"

  if [ -z "$prompt" ]; then
    echo -e "\033[1;31m[!] Prompt mancante\033[0m"
    return 1
  fi

  full_prompt="$base_prompt $prompt"
  echo "$full_prompt" | ollama run mistral | tee /tmp/ai_response

  # Estrai solo il codice tra i blocchi ```
  tmpfile=$(mktemp /tmp/ai_script_XXXX.py)
  awk '
    BEGIN { in_code=0 }
    /^\s*```/ {
      if (in_code == 0) { in_code=1; next }
      else { exit }
    }
    in_code { print }
  ' /tmp/ai_response | sed '/^\s*$/d' > "$tmpfile"

  while true; do
    read -rp "Eseguire? [Y/n/e] " scelta
    scelta=${scelta,,}  # minuscolo

    if [ -z "$scelta" ] || [ "$scelta" = "y" ]; then
      chmod +x "$tmpfile"
      python3 "$tmpfile"
      break
    elif [ "$scelta" = "n" ]; then
      echo "Annullato."
      break
    elif [ "$scelta" = "e" ]; then
      editor=${EDITOR:-nano}
      "$editor" "$tmpfile"
    else
      echo "Scelta non valida."
    fi
  done

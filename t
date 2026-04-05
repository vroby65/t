#!/usr/bin/env bash

set -u

auto_yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y)
      auto_yes=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf '\033[1;31m[!] Opzione non valida: %s\033[0m\n' "$1" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

base_prompt="Scrivi SOLO un blocco di codice python racchiuso in triple backticks, senza testo fuori dal blocco. Scrivi solo il codice python. privilegia l'uso di subprocess. Nessun commento. Nessuna spiegazione. Specifica sempre che è python. Un solo blocco di codice:"
prompt="$*"

if [[ -z "$prompt" ]]; then
  printf '\033[1;31m[!] Prompt mancante\033[0m\n'
  exit 1
fi

full_prompt="$base_prompt $prompt"
ollama_args=(run qwen3-coder-next:cloud)

if (( auto_yes )); then
  ollama_args+=(--hidethinking)
fi

if (( auto_yes )); then
  printf '%s\n' "$full_prompt" | ollama "${ollama_args[@]}" > /tmp/ai_response
else
  printf '%s\n' "$full_prompt" | ollama "${ollama_args[@]}" | tee /tmp/ai_response
fi

printf '\n'

tmpfile="$(mktemp "$HOME/ai_script_XXXX.py")"

awk '
  BEGIN { in_code=0 }
  /^[[:space:]]*```/ {
    if (in_code == 0) { in_code=1; next }
    else { exit }
  }
  in_code { print }
' /tmp/ai_response | sed '/^[[:space:]]*$/d' > "$tmpfile"

sed -i "s/os.getenv('LOCALAPPDATA')/os.getenv('LOCALAPPDATA') or os.path.expanduser('~\/.config')/g" "$tmpfile"

while true; do
  if (( auto_yes )); then
    scelta="y"
  else
    read -r -p "Eseguire? [Y/n/e] " scelta
    [[ -z "$scelta" ]] && scelta="y"
  fi

  case "$scelta" in
    Y|y)
      printf '\033[1;34m🚀 Running script...\033[0m\n'
      cwd="$(pwd)"
      venvdir="$HOME/.venv-runpy"
      mkdir -p "$venvdir"

      chmod +x "$tmpfile"
      runpy "$tmpfile"
      printf '\033[1;32m✅ Esecuzione completata.\033[0m\n'

      shortname="$(basename "$tmpfile")"
      rm -rf "$venvdir/$shortname"
      cd "$cwd" || exit 1

      if (( auto_yes )); then
        rm -f "$tmpfile"
      else
        printf 'File: \033[1;33m%s\033[0m\n' "$tmpfile"

        read -r -p "Vuoi salvare lo script? [y/N] " save_choice
        if [[ "$save_choice" == "y" ]]; then
          read -r -p "Percorso destinazione (default ~/): " save_path
          [[ -z "$save_path" ]] && save_path="$HOME"
          save_path="${save_path/#\~/$HOME}"

          read -r -p "Nome file (default ai_saved.py): " save_name
          [[ -z "$save_name" ]] && save_name="ai_saved.py"

          dest="$save_path/$save_name"
          cp "$tmpfile" "$dest"
          printf '\033[1;32m💾 Salvato in %s\033[0m\n' "$dest"
        fi
      fi
      break
      ;;

    N|n)
      echo "Annullato."
      break
      ;;

    E|e)
      editor="${EDITOR:-micro}"
      "$editor" "$tmpfile"
      ;;

    *)
      echo "Scelta non valida."
      ;;
  esac
done

#!/usr/bin/env bash

base_prompt="Scrivi SOLO un blocco di codice python racchiuso in triple backticks, senza testo fuori dal blocco. Scrivi solo il codice python. privilegia l'uso di subprocess. Nessun commento. Nessuna spiegazione. Specifica sempre che è python. Un solo blocco di codice:"

# unisci tutto il resto del comando in un'unica stringa
prompt="$*"

if [[ -z "$prompt" ]]; then
    echo -e "\033[1;31m[!] Prompt mancante\033[0m"
    exit 1
fi

full_prompt="$base_prompt $prompt"

# esegui ollama
echo "$full_prompt" | ollama run deepseek-v3.1:671b-cloud --hidethinking | tee /tmp/ai_response
echo

# crea file temporaneo
tmpfile=$(mktemp "$HOME/ai_script_XXXX.py")

# estrai codice
awk '
  BEGIN { in_code=0 }
  /^\s*```/ {
    if (in_code == 0) { in_code=1; next }
    else { exit }
  }
  in_code { print }
' /tmp/ai_response | sed '/^\s*$/d' > "$tmpfile"

# patch LOCALAPPDATA su Linux
sed -i "s/os.getenv('LOCALAPPDATA')/os.getenv('LOCALAPPDATA') or os.path.expanduser('~\/.config')/g" "$tmpfile"

while true; do
    read -p "Eseguire? [Y/n/e] " scelta
    scelta=${scelta:-y}

    case "$scelta" in
        Y|y)
            echo -e "\033[1;34m🚀 Running script...\033[0m"

            cwd=$(pwd)
            venvdir="$HOME/.venv-runpy"
            mkdir -p "$venvdir"

            chmod +x "$tmpfile"

            runpy "$tmpfile"

            echo -e "\033[1;32m✅ Esecuzione completata.\033[0m"
            echo -e "File: \033[1;33m$tmpfile\033[0m"

            # pulizia
            rm -rf "$venvdir/$(basename "$tmpfile")"
            cd "$cwd"

            # salvataggio
            read -p "Vuoi salvare lo script? [y/N] " save_choice
            if [[ "$save_choice" == "y" ]]; then
                read -p "Percorso destinazione (default ~/): " save_path
                save_path=${save_path:-$HOME}

                read -p "Nome file (default ai_saved.py): " save_name
                save_name=${save_name:-ai_saved.py}

                dest="$save_path/$save_name"
                cp "$tmpfile" "$dest"
                echo -e "\033[1;32m💾 Salvato in $dest\033[0m"
            fi

            break
        ;;

        N|n)
            echo "Annullato."
            break
        ;;

        E|e)
            editor="${EDITOR:-nano}"
            "$editor" "$tmpfile"
        ;;

        *)
            echo "Scelta non valida."
        ;;
    esac
done

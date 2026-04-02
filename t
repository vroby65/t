#!/usr/bin/env bash

auto_yes=0

while getopts ":y" opt; do
    case "$opt" in
        y)
            auto_yes=1
            ;;
        \?)
            echo "Uso: $0 [-y] prompt"
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

base_prompt="Scrivi SOLO un blocco di codice python racchiuso in triple backticks, senza testo fuori dal blocco. Scrivi solo il codice python. privilegia l'uso di subprocess. Nessun commento. Nessuna spiegazione. Specifica sempre che è python. Un solo blocco di codice:"
prompt="$*"

if [[ -z "$prompt" ]]; then
    echo -e "\033[1;31m[!] Prompt mancante\033[0m"
    exit 1
fi

full_prompt="$base_prompt $prompt"
ollama_args=(run deepseek-v3.2:cloud)
if [[ $auto_yes -eq 1 ]]; then
    ollama_args+=(--hidethinking)
fi

echo "$full_prompt" | ollama "${ollama_args[@]}" | tee /tmp/ai_response
echo

tmpfile=$(mktemp "$HOME/ai_script_XXXX.py")

awk '
  BEGIN { in_code=0 }
  /^\s*```/ {
    if (in_code == 0) { in_code=1; next }
    else { exit }
  }
  in_code { print }
' /tmp/ai_response | sed '/^\s*$/d' > "$tmpfile"

sed -i "s/os.getenv('LOCALAPPDATA')/os.getenv('LOCALAPPDATA') or os.path.expanduser('~\/.config')/g" "$tmpfile"

while true; do
    if [[ $auto_yes -eq 1 ]]; then
        scelta="y"
    else
        read -r -p "Eseguire? [Y/n/e] " scelta
        scelta=${scelta:-y}
    fi

    case "$scelta" in
        Y|y)
            echo -e "\033[1;34m🚀 Running script...\033[0m"
            cwd=$(pwd)
            venvdir="$HOME/.venv-runpy"
            mkdir -p "$venvdir"

            chmod +x "$tmpfile"
            runpy "$tmpfile"
            echo -e "\033[1;32m✅ Esecuzione completata.\033[0m"

            shortname=$(basename "$tmpfile")
            rm -rf "$venvdir/$shortname"
            cd "$cwd" || exit 1

            if [[ $auto_yes -eq 1 ]]; then
                rm -f "$tmpfile"
            else
                echo -e "File: \033[1;33m$tmpfile\033[0m"

                read -r -p "Vuoi salvare lo script? [y/N] " save_choice
                if [[ "$save_choice" == "y" ]]; then
                    read -r -p "Percorso destinazione (default ~/): " save_path
                    save_path=${save_path:-$HOME}

                    read -r -p "Nome file (default ai_saved.py): " save_name
                    save_name=${save_name:-ai_saved.py}

                    dest="$save_path/$save_name"
                    cp "$tmpfile" "$dest"
                    echo -e "\033[1;32m💾 Salvato in $dest\033[0m"
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

# exec AI
function t
  argparse -n t 'y' -- $argv
  or return 1

  set -l auto_yes 0
  if set -q _flag_y
    set auto_yes 1
  end

  set -l base_prompt "Scrivi SOLO un blocco di codice python racchiuso in triple backticks, senza testo fuori dal blocco. Scrivi solo il codice python. privilegia l'uso di subprocess. Nessun commento. Nessuna spiegazione. Specifica sempre che è python. Un solo blocco di codice:"
  set -l prompt (string join " " $argv)

  if test -z "$prompt"
    echo -e "\033[1;31m[!] Prompt mancante\033[0m"
    return 1
  end

  set -l full_prompt "$base_prompt $prompt"
  set -l ollama_args run qwen3-coder-next:cloud --nowordwrap
  set -l temp_root /tmp
  if set -q TMPDIR; and test -n "$TMPDIR"
    set temp_root "$TMPDIR"
  end
  set -l response_file (mktemp "$temp_root/ai_response_XXXX.txt")
  if test $auto_yes -eq 1
    set -a ollama_args --hidethinking
  end

  if test $auto_yes -eq 1
    echo "$full_prompt" | ollama $ollama_args > "$response_file"
  else
    echo "$full_prompt" | ollama $ollama_args | tee "$response_file"
  end
  echo -e "\n"

  set -l tmpfile (mktemp "$PWD/ai_script_XXXX.py")

  perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g' "$response_file" | awk '
    BEGIN { in_code=0 }
    /^[[:space:]]*```/ {
      if (in_code == 0) { in_code=1; next }
      else { exit }
    }
    in_code { print }
  ' | sed '/^[[:space:]]*$/d' > "$tmpfile"

  rm -f "$response_file"

  # patch automatica per LOCALAPPDATA su Linux
  sed -i "s/os.getenv('LOCALAPPDATA')/os.getenv('LOCALAPPDATA') or os.path.expanduser('~\/.config')/g" "$tmpfile"

  while true
    set -l scelta
    if test $auto_yes -eq 1
      set scelta "y"
    else
      read --prompt-str "Eseguire? [Y/n/e] " scelta
      if test -z "$scelta"
        set scelta "y"
      end
    end

    switch $scelta
      case Y y
        echo -e "\033[1;34m🚀 Running script...\033[0m"
        chmod +x "$tmpfile"
        runpy "$tmpfile"
        echo -e "\033[1;32m✅ Esecuzione completata.\033[0m"

        if test $auto_yes -eq 1
          rm -f "$tmpfile"
        else
          echo -e "File: \033[1;33m$tmpfile\033[0m"

          # chiedi se salvare
          read -l --prompt-str "Vuoi salvare lo script? [y/N] " save_choice
          if test "$save_choice" = "y"
            read -l --prompt-str "Percorso destinazione (default ./): " save_path
            if test -z "$save_path"
              set save_path $PWD
            end
            set save_path (string replace -r '^~' $HOME -- "$save_path")
            read -l --prompt-str "Nome file (default ai_saved.py): " save_name
            if test -z "$save_name"
              set save_name "ai_saved.py"
            end
            set dest "$save_path/$save_name"
            cp "$tmpfile" "$dest"
            echo -e "\033[1;32m💾 Salvato in $dest\033[0m"
          end
        end
        break

      case N n
        echo "Annullato."
        break

      case E e
        set -l editor $EDITOR
        if test -z "$editor"
          set editor micro
        end
        $editor "$tmpfile"

      case '*'
        echo "Scelta non valida."
    end
  end
end

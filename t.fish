function t
  set -l base_prompt "Scrivi SOLO un blocco di codice python racchiuso in triple backticks, senza testo fuori dal blocco. Scrivi solo il codice python. privilegia l'uso di subprocess. Nessun commento. Nessuna spiegazione. Specifica sempre che è python. Un solo blocco di codice:"
  set -l prompt (string join " " $argv)

  if test -z "$prompt"
    echo -e "\033[1;31m[!] Prompt mancante\033[0m"
    return 1
  end

  set -l full_prompt "$base_prompt $prompt"
  echo "$full_prompt" | ollama run deepseek-v3.1:671b-cloud  --hidethinking | tee /tmp/ai_response
  echo -e "\n"

  # crea un file temporaneo nella home
  set -l tmpfile (mktemp ~/ai_script_XXXX.py)

  # estrae solo il blocco di codice
  awk '
    BEGIN { in_code=0 }
    /^\s*```/ {
      if (in_code == 0) { in_code=1; next }
      else { exit }
    }
    in_code { print }
  ' /tmp/ai_response | sed '/^\s*$/d' > $tmpfile

  # patch automatica per LOCALAPPDATA su Linux
  sed -i "s/os.getenv('LOCALAPPDATA')/os.getenv('LOCALAPPDATA') or os.path.expanduser('~\/.config')/g" $tmpfile

  while true
    read -l --prompt-str "Eseguire? [Y/n/e] " scelta
    if test -z "$scelta"
      set scelta "y"
    end

    switch $scelta
      case Y y
        echo -e "\033[1;34m🚀 Running script...\033[0m"
        set -l cwd (pwd)
        set -l venvdir "$HOME/.venv-runpy"
        mkdir -p $venvdir

        chmod +x $tmpfile
        runpy $tmpfile
        echo -e "\033[1;32m✅ Esecuzione completata.\033[0m"
        echo -e "File: \033[1;33m$tmpfile\033[0m"

        set shortname (basename "$tmpfile")
        rm -rf "$venvdir/$shortname"
        cd $cwd

        # chiedi se salvare
        read -l --prompt-str "Vuoi salvare lo script? [y/N] " save_choice
        if test "$save_choice" = "y"
          read -l --prompt-str "Percorso destinazione (default ~/): " save_path
          if test -z "$save_path"
            set save_path ~
          end
          read -l --prompt-str "Nome file (default ai_saved.py): " save_name
          if test -z "$save_name"
            set save_name "ai_saved.py"
          end
          set dest "$save_path/$save_name"
          cp "$tmpfile" "$dest"
          echo -e "\033[1;32m💾 Salvato in $dest\033[0m"
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
        $editor $tmpfile

      case '*'
        echo "Scelta non valida."
    end
  end
end

function t
  set -l base_prompt "Scrivi solo il codice Python. Nessuna dipendenza esterna. Nessun commento. Nessuna spiegazione. Un solo blocco di codice:"
  set -l prompt (string join " " $argv)

  if test -z "$prompt"
    echo -e "\033[1;31m[!] Prompt mancante\033[0m"
    return 1
  end

  set -l full_prompt "$base_prompt $prompt"

  echo "$full_prompt" | ollama run mistral | tee /tmp/ai_response

  echo -e "\n"

  # Estrai solo il codice
  set -l tmpfile (mktemp /tmp/ai_script_XXXX.py)
  awk '
    BEGIN { in_code=0 }
    /^\s*```/ {
      if (in_code == 0) { in_code=1; next }
      else { exit }
    }
    in_code { print }
  ' /tmp/ai_response | sed '/^\s*$/d' > $tmpfile

  while true
    read -l --prompt-str "Eseguire? [Y/n/e] " scelta
    if test -z "$scelta"
      set scelta "y"
    end

    switch $scelta
      case Y y
        chmod +x $tmpfile
        python3 $tmpfile
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

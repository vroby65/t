#!/usr/bin/env bash
# t - Assistente al codice per Ollama (versione Bash)
# Autore: Roby + GPT-5
# Ultima revisione: 2025-10-26

set -e

BASE_PROMPT="Scrivi solo il codice python. privilegia l'uso di subprocess. Nessun commento. Nessuna spiegazione. Un solo blocco di codice:"

if [ $# -eq 0 ]; then
  echo -e "\033[1;31m[!] Prompt mancante\033[0m"
  echo "Uso: t <prompt>"
  exit 1
fi

PROMPT="$*"
FULL_PROMPT="$BASE_PROMPT $PROMPT"

# Esegui richiesta a Ollama
echo -e "\033[1;33m[+] Invio prompt a Ollama...\033[0m"
echo "$FULL_PROMPT" | ollama run deepseek-v3.1:671b-cloud | tee /tmp/ai_response
echo

# Crea file temporaneo nella home
TMPFILE=$(mktemp ~/ai_script_XXXX.py)

# Estrai solo il codice Python
awk '
  BEGIN { in_code=0 }
  /^\s*```/ {
    if (in_code == 0) { in_code=1; next }
    else { exit }
  }
  in_code { print }
' /tmp/ai_response | sed '/^\s*$/d' > "$TMPFILE"

# Patch LOCALAPPDATA per compatibilità Linux
sed -i "s/os.getenv('LOCALAPPDATA')/os.getenv('LOCALAPPDATA') or os.path.expanduser('~\/.config')/g" "$TMPFILE"

# Loop di esecuzione
while true; do
  read -rp "Eseguire? [Y/n/e] " scelta
  [ -z "$scelta" ] && scelta="y"

  case "$scelta" in
    Y|y)
      echo -e "\033[1;34m🚀 Running script...\033[0m"
      CWD=$(pwd)
      VENVDIR="$HOME/.venv-runpy"
      mkdir -p "$VENVDIR"

      chmod +x "$TMPFILE"
      runpy "$TMPFILE"
      echo -e "\033[1;32m✅ Esecuzione completata.\033[0m"
      echo -e "File: \033[1;33m$TMPFILE\033[0m"

      SHORTNAME=$(basename "$TMPFILE")
      rm -rf "$VENVDIR/$SHORTNAME"
      cd "$CWD" || true

      # Chiedi se salvare
      read -rp "Vuoi salvare lo script? [y/N] " SAVE_CHOICE
      if [[ "$SAVE_CHOICE" =~ ^[Yy]$ ]]; then
        read -rp "Percorso destinazione (default ~/): " SAVE_PATH
        [ -z "$SAVE_PATH" ] && SAVE_PATH="$HOME"
        read -rp "Nome file (default ai_saved.py): " SAVE_NAME
        [ -z "$SAVE_NAME" ] && SAVE_NAME="ai_saved.py"
        DEST="$SAVE_PATH/$SAVE_NAME"
        cp "$TMPFILE" "$DEST"
        echo -e "\033[1;32m💾 Salvato in $DEST\033[0m"
      fi
      break
      ;;
    N|n)
      echo "Annullato."
      break
      ;;
    E|e)
      EDITOR="${EDITOR:-micro}"
      "$EDITOR" "$TMPFILE"
      ;;
    *)
      echo "Scelta non valida."
      ;;
  esac
done

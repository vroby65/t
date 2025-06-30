# t

`t` is a terminal script (for Bash and Fish) that sends a prompt to [Ollama](https://ollama.com) using the `mistral` model, extracts only the Python code from the response, and lets you choose whether to run, edit, or discard it.

## Features

- Sends prompts to `ollama run mistral`
- Filters and extracts only the Python code block
- Prompts to run/edit/discard the result
- Minimal: no external Python libraries used
- Works in both Bash and Fish

---

## Requirements

- [Ollama](https://ollama.com) installed
- The `mistral` model pulled (`ollama pull mistral`)
- Python 3
- An editor like `nano`, `vim`, etc. (respects `$EDITOR`)

---

## Installation (Bash)

1. Save the script as `t` and make it executable:
   ```bash
   chmod +x t
   ```

2. Move it to a directory in your `$PATH`:

   ```bash
   sudo mv t /usr/local/bin/
   ```

3. Use it:

   ```bash
   t "write a function that sums two numbers"
   ```

---

## Installation (Fish shell)

1. Create the file `~/.config/fish/functions/t.fish` with the following content:

````fish
function t
  set -l base_prompt "Scrivi solo il codice Python. Nessuna dipendenza esterna. Nessun commento. Nessuna spiegazione. Un solo blocco di codice:"
  set -l prompt (string join " " $argv)

  if test -z "$prompt"
    echo -e "\033[1;31m[!] Missing prompt\033[0m"
    return 1
  end

  set -l full_prompt "$base_prompt $prompt"
  echo "$full_prompt" | ollama run mistral | tee /tmp/ai_response

  set -l tmpfile (mktemp /tmp/ai_script_XXXX.py)
  awk '
    BEGIN { in_code=0 }
    /^\s*```/ {
      if (in_code == 0) { in_code=1; next }
      else { exit }
    }
    in_code { print }
  ' /tmp/ai_response | sed '/^\s*$/d' > "$tmpfile"

  while true
    read -l -P "Run it? [Y/n/e] " choice
    set choice (string lower "$choice")

    if test -z "$choice" -o "$choice" = "y"
      chmod +x "$tmpfile"
      python3 "$tmpfile"
      break
    else if test "$choice" = "n"
      echo "Cancelled."
      break
    else if test "$choice" = "e"
      set -l editor (set -q EDITOR; and echo $EDITOR; or echo nano)
      $editor "$tmpfile"
    else
      echo "Invalid choice."
    end
  end
end
````

2. Save and make it available with:

```fish
funcsave t
```

3. Then use it like this:

```fish
t "create a class named Point with x and y attributes"
```

---

## Example

```bash
t "function to calculate the greatest common divisor"
```

Response:

```python
def gcd(a, b):
    while b:
        a, b = b, a % b
    return a
```

---

## License

Distributed under the [MIT License](LICENSE).

````

---

### ✅ `LICENSE` (MIT License)

```text
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
````

---

### ✅ `.gitignore`

```gitignore
# Temporary files
*.pyc
__pycache__/
*.swp

# AI output files
/tmp/ai_response
/tmp/ai_script_*.py

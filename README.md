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

1. Copy the file t.fisn in

2. `~/.config/fish/functions/`  and runpy in `/usr/local/bin`

3. Save and make it available with:

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

```
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
```

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
```

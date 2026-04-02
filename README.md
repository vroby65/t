# t

`t` is a small Bash/Fish helper that sends a prompt to [Ollama](https://ollama.com), asks `deepseek-v3.2:cloud` to return only Python code, extracts the first fenced code block, and lets you run, edit, discard, or save the generated script.

## Features

- Bash script (`t`) and Fish function (`t.fish`)
- Uses `ollama run deepseek-v3.2:cloud`
- Supports `-y` for non-interactive execution
- Adds `--hidethinking` automatically when `-y` is used
- Extracts only the Python code block from the model output
- Applies a Linux fallback for `LOCALAPPDATA`
- Uses `runpy` to install dependencies and run the generated script
- Respects `$EDITOR`; defaults to `micro`

## What `runpy` does

`runpy` analyzes the generated Python file, detects third-party imports with AST parsing, includes dependencies from a nearby `requirements.txt` when present, creates an isolated virtual environment, installs dependencies, runs the script, and removes the environment afterwards.

It also resolves several common import-to-package mismatches such as:

- `cv2` -> `opencv-python`
- `PIL` -> `Pillow`
- `yaml` -> `PyYAML`
- `sklearn` -> `scikit-learn`

## Requirements

- [Ollama](https://ollama.com) installed
- `deepseek-v3.2:cloud` available locally:

```bash
ollama pull deepseek-v3.2:cloud
```

- Python 3 with `venv`
- `runpy` available in your `PATH`
- `fish` only if you want the Fish function
- An editor in `$EDITOR`, or `micro`

## Installation (Bash)

```bash
chmod +x t runpy
sudo cp t /usr/local/bin/t
sudo cp runpy /usr/local/bin/runpy
```

## Installation (Fish)

```bash
chmod +x t.fish runpy
cp t.fish ~/.config/fish/functions/t.fish
sudo cp runpy /usr/local/bin/runpy
```

Open a new Fish session or reload the function:

```fish
functions -e t
source ~/.config/fish/functions/t.fish
```

## Usage

Interactive mode:

```bash
t "write a function that sums two numbers"
```

Auto-confirm mode:

```bash
t -y "download a file and extract it"
```

Fish usage:

```fish
t "create a class named Point with x and y attributes"
```

## Behavior

- Without `-y`, `t` shows the model output, asks whether to run the script, and lets you save it afterwards.
- With `-y`, `t` skips the prompt, runs the script immediately, and removes the temporary file afterwards.
- Choosing `e` opens the generated script in your editor before execution.

## License

This repository does not currently include a separate `LICENSE` file.

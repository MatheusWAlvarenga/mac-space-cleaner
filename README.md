# mac-space-cleaner

```
++--------------------------------------------------------------++
||                                                              ||
||                   MAC SPACE CLEANER                          ||
||                                                              ||
++--------------------------------------------------------------++
```

A small, interactive shell script to safely reclaim disk space on macOS by cleaning caches and other unnecessary developer artifacts.

This tool is intended for developers who see large, unexplained "System Data" or otherwise need a reliable way to remove developer-related disk bloat.

---

## Overview

`mac-space-cleaner` helps you safely analyze and remove files that commonly consume space on developer machines, including caches, build artifacts, and old `node_modules` folders. The script is interactive, shows size estimates before deleting, and supports a dry-run mode so you can preview changes.

Key capabilities:

- Interactive terminal menu
- Two cleanup modes: `light` (safe/basic) and `deep` (aggressive)
- Per-item confirmation and disk-space estimation before removal
- `--dry-run` simulation mode (no files are removed)
- Final report showing reclaimed space and optional reboot prompt

---

## Features

- Interactive menu-driven UI
- Light and Deep cleanup modes
- Estimates space to be freed before deleting
- Prompts for emptying Trash and removing each `node_modules` (shows size)
- Final summary with total freed space
- Optional reboot to refresh macOS system data

---

## Requirements

- macOS (Intel or Apple Silicon)
- Bash (sh-compatible shell)
- Administrator privileges only if an optional reboot is performed

---

## Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/MatheusWAlvarenga/mac-space-cleaner.git
cd mac-space-cleaner
chmod +x mac_space_cleaner.sh
```

Note: Replace `YOUR_USERNAME` with your GitHub username if using the repo URL above.

---

## Usage

Run the script (recommended to try `--dry-run` first):

```bash
./mac_space_cleaner.sh --dry-run
```

To perform the actual cleanup, run without `--dry-run`:

```bash
./mac_space_cleaner.sh
```

The script will present an interactive menu and show estimated sizes before any deletion.

---

## Screenshots

<img width="711" height="152" alt="Screenshot 2025-12-26 at 18 28 50" src="https://github.com/user-attachments/assets/b1caad80-cea3-4002-a9ff-83df6ae35e32" />

<img width="711" height="317" alt="Screenshot 2025-12-26 at 18 29 12" src="https://github.com/user-attachments/assets/8813d8f5-a8e6-4f66-8ebe-87f5ac7f146d" />

- Cleanup mode selection
- Estimated disk space before deletion
- Interactive confirmations
- Final cleanup report

---

## Safety Notes

This script permanently deletes files. Please:

- Read each confirmation prompt carefully.
- Always run with `--dry-run` first to verify what will be removed.
- Avoid running the script as the `root` user.

The author is not responsible for data loss. Use at your own risk.

---

## Contributing

Contributions are welcome. Ways to help:

- Open issues for bugs or feature requests
- Submit pull requests with improvements
- Suggest additional cache locations or refinements to estimation logic

Please follow standard GitHub contribution workflows and include documentation for changes.

---

## Roadmap

- Add a whitelist to exclude specific folders
- Scan multiple directories (e.g., `~/dev`, `~/projects`)
- Export a cleanup report to a file
- Add scheduled execution / cron support
- Provide a `zsh` plugin or Homebrew formula

---

## License

MIT License

# 🧹 mac-space-cleaner

An interactive script to **intelligently clean cache and unnecessary files on macOS**, focused on developers who struggle with the infamous **“System Data” consuming tens of gigabytes**.

This project aims to **safely free disk space**, giving full control to the user over what will be removed.

---

## 🚀 Why does this project exist?

If you:

- Use macOS for development
- Work with Node.js, Docker, Xcode, Android, or multiple projects
- Have seen your Mac storage fill up **without a clear explanation**

…then this script is for you.

**mac-space-cleaner** helps you:

- Clean common and advanced caches
- Identify and remove old `node_modules`
- Empty the Trash in a conscious, interactive way
- See **how much space will be and was freed**
- Finish everything with an optional reboot (recommended for “System Data” refresh)

---

## ✨ Features

- ✅ Interactive terminal menu
- ✅ Two cleanup modes:
  - **Light** – basic cache cleanup
  - **Deep** – aggressive cleanup (dev tools, simulators, Node.js, etc.)
- ✅ Disk space estimation **before** deleting anything
- ✅ Confirmation prompts for:
  - Emptying the Trash
  - Removing each `node_modules` folder (showing project name and size)
- ✅ Final report showing freed disk space
- ✅ Optional reboot to fully reclaim “System Data”
- ✅ `--dry-run` mode (simulation, no files are removed)

---

## 🖥️ Requirements

- macOS
- Bash
- Administrator permissions (only required for reboot)

---

## 📦 Installation

```bash
git clone https://github.com/YOUR_USERNAME/mac-space-cleaner.git
cd mac-space-cleaner
chmod +x mac_space_cleaner.sh
▶️ Usage
Normal execution
bash
Copy code
./mac_space_cleaner.sh
Simulation mode (recommended for first run)
bash
Copy code
./mac_space_cleaner.sh --dry-run
📸 Screenshots
Add screenshots of the process here:

Cleanup mode selection

Estimated disk space to be freed

Interactive deletion confirmations

Final cleanup report

⚠️ Important Notice
This script permanently deletes files from your system.

Carefully read every confirmation prompt

Always run with --dry-run first

Do not run as root

The author is not responsible for misuse or data loss

🤝 Contributing
Contributions are welcome and appreciated!

You can help by:

Opening issues

Submitting pull requests

Suggesting new cache locations

Improving estimation logic or performance

Please make sure your contributions are well documented.

🔮 Roadmap
 Project whitelist (exclude specific folders)

 Scan multiple directories (e.g. ~/dev, ~/projects)

 Export cleanup report to a file

 Scheduled execution

 zsh plugin integration

📄 License
MIT License

yaml
Copy code

---

Se quiser, no próximo passo posso:
- Ajustar o README para **tom mais técnico ou mais simples**
- Criar um **CONTRIBUTING.md**
- Criar um **CHANGELOG.md**
- Sugerir badges (license, shellcheck, stars)
- Escrever a descrição da **Release v1.0.0**

Esse repo tem tudo para virar utilitário de referência 🚀
```

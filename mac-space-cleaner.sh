#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# MAC SPACE CLEANER PRO (INTERACTIVE)
# ==========================================

DRY_RUN=0
MODE=""

# ---- COLORS ----
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
ORANGE='\033[0;38;5;208m'
NC='\033[0m' # No Color

# Script directory (used to find bundled assets)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
  if [ -f "$SCRIPT_DIR/assets/logo.txt" ]; then
    printf "${GREEN}\n"
    sed 's/^/ /' "$SCRIPT_DIR/assets/logo.txt"
    printf "${NC}\n"
  fi
}

log_info()    { printf "\n${BLUE}💡 %s${NC}\n" "$1"; }
log_success() { printf "${GREEN}✅ %s${NC}\n" "$1"; }
log_warn()    { printf "${YELLOW}⚠️  %s${NC}\n" "$1"; }
log_action()  { printf "${YELLOW}> %s...${NC}\n" "$1"; }

# ---- ARGS ----
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) ;;
  esac
done

# ---- UTILS ----
disk_free() {
  df -k / | tail -1 | awk '{print $4}'
}

human() {
  awk "BEGIN {printf \"%.2f GB\", $1/1024/1024}"
}

prompt_yes_no() {
  read -r -p "$(printf "${RED}%s [y/N]: ${NC}" "$1")" ans
  [[ "$ans" =~ ^[yYsS]$ ]]
}

run_rm() {
  local target="$1"
  if [ "$DRY_RUN" -eq 0 ]; then
    if [[ "$target" == *"*"* ]]; then
      find "${target%/*}" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
    else
      rm -rf "$target" 2>/dev/null || true
    fi
  else
    log_warn "(dry-run) Would remove: $target"
  fi
}

empty_trash() {
  if [ "$DRY_RUN" -eq 0 ]; then
    log_action "Emptying Trash via System Events"
    osascript -e 'tell application "Finder" to empty trash' 2>/dev/null || true
    rm -rf "$HOME/.Trash/"* 2>/dev/null || true
  else
    log_warn "(dry-run) Would empty trash"
  fi
}

show_details() {
  printf "\n${BLUE}%s${NC}\n" "------------------------------------------"
  printf "   ${BLUE}CLEANING DETAILS${NC}\n"
  printf "${BLUE}%s${NC}\n" "------------------------------------------"
  printf "${GREEN}1) LIGHT CLEANUP:${NC}\n"
  printf "   - User Caches (~/Library/Caches)\n"
  printf "   - System Logs (~/Library/Logs)\n"
  printf "   - Telegram/Spotify temporary caches\n\n"
  printf "   - Downloads: Optionally clear ~/Downloads\n\n"
  
  printf "${ORANGE}2) DEEP CLEANUP (Includes Light +):${NC}\n"
  printf "   - Xcode: DerivedData, Archives, iOS Support\n"
  printf "   - Dev Tools: Gradle, NPM, Cocoapods\n"
  printf "   - Homebrew: Old versions & downloads\n"
  printf "   - Trash: Optionally empty system trash folder\n"
  printf "   - Downloads: Optionally clear ~/Downloads\n"
  printf "   - RAM: Purge inactive memory\n"
  printf "${BLUE}%s${NC}\n\n" "------------------------------------------"
}

# ---- EXTRA CLEANERS ----
clean_docker() {
  if ! command -v docker &>/dev/null; then
    log_warn "Docker not installed or not in PATH; skipping Docker cleanup"
    return
  fi

  log_action "Checking Docker state"
  if [ "$DRY_RUN" -eq 1 ]; then
    log_warn "(dry-run) Would list containers, images, volumes and perform pruning"
    docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || true
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null || true
    return
  fi

  if prompt_yes_no "Stop all running Docker containers?"; then
    docker ps -q | xargs -r docker stop || true
  fi

  if prompt_yes_no "Remove all stopped containers and dangling images (docker system prune)?"; then
    docker system prune -af || true
  fi

  if prompt_yes_no "Remove unused volumes?"; then
    docker volume prune -f || true
  fi
}

clean_photos() {
  # remove known Photos caches in user container paths (safe targets)
  log_action "Cleaning Photos caches (container caches and thumbnails)"
  run_rm "$HOME/Library/Containers/com.apple.Photos/Data/Library/Caches/*"
  run_rm "$HOME/Library/Containers/com.apple.ImageKit.References/Data/Library/Caches/*"
  run_rm "$HOME/Library/Caches/com.apple.Photos/*"
  if prompt_yes_no "Remove Photos app previews inside your Photos Library (may force regenerate)?"; then
    run_rm "$HOME/Pictures/Photos Library.photoslibrary/resources/previews/*"
  fi
}

clean_python_node() {
  log_action "Cleaning Python and Node caches"

  # pip cache
  if command -v pip &>/dev/null || command -v pip3 &>/dev/null; then
    if command -v pip &>/dev/null && pip cache purge &>/dev/null; then
      if [ "$DRY_RUN" -eq 0 ]; then
        pip cache purge || true
      else
        log_warn "(dry-run) Would run 'pip cache purge'"
      fi
    else
      run_rm "$HOME/.cache/pip/*"
      run_rm "$HOME/.pip/cache/*"
    fi
  else
    log_warn "pip not found; skipping pip cleanup"
  fi

  # npm / yarn
  if command -v npm &>/dev/null; then
    if [ "$DRY_RUN" -eq 0 ]; then
      npm cache clean --force &>/dev/null || run_rm "$HOME/.npm/_cacache"
    else
      log_warn "(dry-run) Would run 'npm cache clean --force' or remove ~/.npm/_cacache"
    fi
  fi

  if command -v yarn &>/dev/null; then
    if [ "$DRY_RUN" -eq 0 ]; then
      yarn cache clean --all &>/dev/null || true
    else
      log_warn "(dry-run) Would run 'yarn cache clean --all'"
    fi
  fi

  if prompt_yes_no "Search and remove common __pycache__ and .pytest_cache directories under your home (dangerous)?"; then
    if [ "$DRY_RUN" -eq 0 ]; then
      find "$HOME" -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -prune -exec rm -rf {} + 2>/dev/null || true
    else
      log_warn "(dry-run) Would find and remove __pycache__ and .pytest_cache under $HOME"
    fi
  fi
}

clean_system_extra() {
  log_action "Cleaning additional system caches and local snapshots"

  # Private var folders (safe to clear cache subpaths)
  if prompt_yes_no "Clear /private/var/folders/* caches (requires sudo)?"; then
    if [ "$DRY_RUN" -eq 0 ]; then
      sudo rm -rf /private/var/folders/*/C/com.apple.Safari/* 2>/dev/null || true
      sudo rm -rf /private/var/folders/*/0/com.apple.Safari/* 2>/dev/null || true
      sudo rm -rf /private/var/folders/*/*/C/* 2>/dev/null || true
    else
      log_warn "(dry-run) Would remove selective caches under /private/var/folders"
    fi
  fi

  # System caches (requires sudo)
  if prompt_yes_no "Clear system caches in /Library/Caches (requires sudo)?"; then
    if [ "$DRY_RUN" -eq 0 ]; then
      sudo rm -rf /Library/Caches/* 2>/dev/null || true
    else
      log_warn "(dry-run) Would remove /Library/Caches/*"
    fi
  fi

  # Time Machine local snapshots
  if command -v tmutil &>/dev/null; then
    if prompt_yes_no "Remove local Time Machine snapshots? (requires sudo)"; then
      if [ "$DRY_RUN" -eq 0 ]; then
        SNAPSHOTS=$(tmutil listlocalsnapshots / 2>/dev/null | awk -F. '{print $1}' )
        for s in $SNAPSHOTS; do
          sudo tmutil deletelocalsnapshots "$s" || true
        done
      else
        log_warn "(dry-run) Would list and delete local Time Machine snapshots via tmutil"
      fi
    fi
  fi
}

clean_project_dirs() {
  log_action "Scanning projects for node_modules and common build artifacts"

  read -r -p "Base directory to scan (default: $HOME): " BASE_DIR
  BASE_DIR=${BASE_DIR:-$HOME}

  if [ ! -d "$BASE_DIR" ]; then
    log_warn "$BASE_DIR does not exist; aborting project scan"
    return
  fi

  # find common project artifact directories
  if [ "$DRY_RUN" -eq 1 ]; then
    log_warn "(dry-run) Would search for node_modules, __pycache__, .venv, .pytest_cache, dist, build under $BASE_DIR"
  fi

  find "$BASE_DIR" -type d \( -name "node_modules" -o -name "__pycache__" -o -name ".venv" -o -name ".pytest_cache" -o -name "dist" -o -name "build" \) -prune 2>/dev/null |
  while IFS= read -r dir; do
    # show relative path for readability
    rel=${dir/#$HOME/~}
    size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    printf "\nFound: %s (%s)\n" "$rel" "$size"
    if prompt_yes_no "Delete this folder?"; then
      run_rm "$dir"
    else
      log_info "Skipped $rel"
    fi
  done

  log_info "Project scan finished"
}

# =============================
# INITIAL STATE
# =============================
SPACE_BEFORE=$(disk_free)

# show ASCII banner
print_banner

# =============================
# MODE SELECTION
# =============================
while true; do
  log_info "Select cleaning mode:"
  printf "${GREEN}1) Light${NC}: Basic caches and logs\n"
  printf "${ORANGE}2) Deep${NC}: Dev tools (Xcode, Docker, Brew)\n"
  echo "3) Details: View process breakdown"
  echo "4) Cancel"
  read -r -p "Option [1-4]: " opt

  case "$opt" in
    1) MODE="LIGHT"; break ;;
    2) MODE="DEEP"; break ;;
    3) show_details ;;
    4) log_info "Operation cancelled by user."; exit 0 ;;
    *) log_warn "Invalid option. Please choose 1-4." ;;
  esac
done

# =============================
# EXECUTION
# =============================
log_info "Starting $MODE cleanup..."

# --- LIGHT CLEAN ---
log_action "Cleaning User Caches and Logs"
run_rm "$HOME/Library/Caches/*"
run_rm "$HOME/Library/Logs/*"
run_rm "$HOME/Library/Application Support/Telegram Desktop/tdata/user_data/cache/*"
run_rm "$HOME/Library/Application Support/Spotify/PersistentCache/*"

# --- DEEP CLEAN ---
if [ "$MODE" = "DEEP" ]; then
  log_action "Cleaning Developer Tools"
  run_rm "$HOME/Library/Developer/Xcode/DerivedData/*"
  run_rm "$HOME/Library/Developer/Xcode/Archives/*"
  run_rm "$HOME/Library/Developer/Xcode/iOS DeviceSupport/*"
  run_rm "$HOME/.gradle/caches"
  run_rm "$HOME/.npm/_cacache"
  run_rm "$HOME/.cocoapods/repos"

  if command -v brew &>/dev/null; then
    log_action "Running Homebrew Cleanup"
    if [ "$DRY_RUN" -eq 0 ]; then
      brew cleanup -s &>/dev/null
      brew autoremove &>/dev/null
    fi
  fi

  if prompt_yes_no "Empty Trash?"; then
    empty_trash
  fi

  if [ -d "$HOME/Downloads" ]; then
    COUNT=$(find "$HOME/Downloads" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | awk 'BEGIN{RS="\0";c=0} {if(length($0)>0) c++} END{print c}')
    if [ "$COUNT" -eq 0 ]; then
      log_warn "No files found in $HOME/Downloads"
    else
      if prompt_yes_no "Delete all files in your Downloads folder ($HOME/Downloads)?"; then
        log_action "Removing contents of Downloads"
        run_rm "$HOME/Downloads/*"
      fi
    fi
  else
    log_warn "$HOME/Downloads does not exist."
  fi

  if [ "$DRY_RUN" -eq 0 ]; then
    log_action "Purging inactive RAM"
    sudo purge || log_warn "Sudo privileges required for RAM purge"
  fi

  # Additional deep-clean steps
  if prompt_yes_no "Include Docker cleanup (stop/prune)?"; then
    clean_docker
  fi

  if prompt_yes_no "Include Photos cache cleanup (container caches)?"; then
    clean_photos
  fi

  if prompt_yes_no "Include Python/Node caches (pip/npm/yarn)?"; then
    clean_python_node
  fi

  if prompt_yes_no "Include additional system cleanup (caches, local snapshots)?"; then
    clean_system_extra
  fi

  if prompt_yes_no "Scan projects for node_modules and other build artifacts?"; then
    clean_project_dirs
  fi
fi

# =============================
# FINAL REPORT
# =============================
SPACE_AFTER=$(disk_free)
FREED=$((SPACE_AFTER - SPACE_BEFORE))

printf "\n${BLUE}==========================================${NC}\n"
log_info "Cleanup Completed"
if [ "$FREED" -le 0 ]; then
  log_success "System was already clean."
else
  log_success "Total space freed: $(human "$FREED")"
fi

log_info "Tip: Restarting your Mac will help clear system temp files."
printf "${BLUE}==========================================${NC}\n\n"

# =============================
# REBOOT OPTION
# =============================
if [ "$DRY_RUN" -eq 0 ] && prompt_yes_no "Would you like to restart your Mac now?"; then
  log_action "Restarting in 5 seconds (Press Ctrl+C to abort)"
  sleep 5
  sudo shutdown -r now
else
  log_success "Cleanup finished. Have a great day!"
fi

exit 0
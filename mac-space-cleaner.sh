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
  printf "   - Docker: Prune system & volumes\n"
  printf "   - Trash: Empty system trash folder\n"
  printf "   - RAM: Purge inactive memory\n"
  printf "${BLUE}%s${NC}\n\n" "------------------------------------------"
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

  if command -v docker &>/dev/null && prompt_yes_no "Cleanup unused Docker system data?"; then
    log_action "Pruning Docker"
    docker system prune -f
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
# =============================================================================
# Modern zsh — fast startup, smart completions, fuzzy search, beautiful prompt
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PATH — user bins (heavy tools lazy-loaded below)
# -----------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# -----------------------------------------------------------------------------
# 2. Theme (macOS) — detect once, set all theme-dependent vars
# -----------------------------------------------------------------------------
if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
  export _ZSH_THEME_MODE=dark
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=250'
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.dark.toml"
else
  export _ZSH_THEME_MODE=light
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.light.toml"
fi

# -----------------------------------------------------------------------------
# 3. Completions — cache 24h to avoid daily regeneration (~100ms saved)
# -----------------------------------------------------------------------------
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# -----------------------------------------------------------------------------
# 4. Lazy-load nvm — shims load nvm on first use
# -----------------------------------------------------------------------------
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [[ -s /opt/homebrew/opt/nvm/nvm.sh ]] && . /opt/homebrew/opt/nvm/nvm.sh
  nvm "$@"
}
node() { nvm; node "$@"; }
npm() { nvm; npm "$@"; }
npx() { nvm; npx "$@"; }

# -----------------------------------------------------------------------------
# 5. Plugins — autosuggestions → fzf → syntax-highlighting (no plugin manager)
# -----------------------------------------------------------------------------
[[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] &&
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] &&
  source /opt/homebrew/opt/fzf/shell/completion.zsh
[[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# -----------------------------------------------------------------------------
# 6. zoxide — smarter cd; use `z` to jump to frequent dirs
# -----------------------------------------------------------------------------
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# -----------------------------------------------------------------------------
# 7. Starship prompt — config set in theme block above
# -----------------------------------------------------------------------------
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# -----------------------------------------------------------------------------
# 8. eza + aliases — coloured listings with git status
# -----------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first --git'
fi

# -----------------------------------------------------------------------------
# 9. GitHub API — PAT for local scripts (e.g. ./scripts/fetch-issues-milestones.sh)
#    Replace the placeholder with your token; never paste tokens into chat or git.
# -----------------------------------------------------------------------------
export GITHUB_TOKEN=
# =============================================================================
# Modern zsh — fast startup, smart completions, fuzzy search, beautiful prompt
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PATH — user bins (heavy tools lazy-loaded below)
# -----------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# Dotfiles checkout: when ~/.zshrc resolves into the repo, put tools/cursor-cli on PATH.
_dotfiles_zshrc="${ZDOTDIR:-$HOME}/.zshrc"
if [[ -e "$_dotfiles_zshrc" ]] && [[ -f "${_dotfiles_zshrc:A:h}/tools/cursor-cli/install-extensions.sh" ]]; then
  export DOTFILES_ROOT="${_dotfiles_zshrc:A:h}"
  export PATH="$DOTFILES_ROOT/tools/cursor-cli:$PATH"
fi
unset _dotfiles_zshrc

# -----------------------------------------------------------------------------
# 2. Theme (macOS) — detect once, set all theme-dependent vars
# -----------------------------------------------------------------------------
# Starship: dark/light only. ~/.config/starship.toml is linked for manual overrides
# (e.g. unset STARSHIP_CONFIG) or tools that do not read this zshrc.
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
  local _nvm_sh=""
  if [[ -s /opt/homebrew/opt/nvm/nvm.sh ]]; then
    _nvm_sh=/opt/homebrew/opt/nvm/nvm.sh
  elif [[ -s /usr/local/opt/nvm/nvm.sh ]]; then
    _nvm_sh=/usr/local/opt/nvm/nvm.sh
  elif [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    _nvm_sh="${NVM_DIR}/nvm.sh"
  fi
  [[ -s "$_nvm_sh" ]] && . "$_nvm_sh"
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
_fzf_base=""
for _fzf_base in /opt/homebrew/opt/fzf /usr/local/opt/fzf; do
  [[ -f "${_fzf_base}/shell/key-bindings.zsh" ]] && break
done
[[ -f "${_fzf_base}/shell/key-bindings.zsh" ]] && source "${_fzf_base}/shell/key-bindings.zsh"
[[ -f "${_fzf_base}/shell/completion.zsh" ]] && source "${_fzf_base}/shell/completion.zsh"
unset _fzf_base
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
# 9. Local overrides — GITHUB_TOKEN, secrets, machine-specific exports (never commit)
# -----------------------------------------------------------------------------
# ~/.zshrc.local: see zshrc.local.example.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Zellij integration
if [[ -o interactive ]] \
  && -z "${ZELLIJ-}" \
  && -z "${DOTFILES_NO_ZELLIJ_AUTOSTART-}" \
  && command -v zellij >/dev/null 2>&1; then

  export ZELLIJ_AUTO_ATTACH="${ZELLIJ_AUTO_ATTACH:-true}"
  export ZELLIJ_AUTO_EXIT="${ZELLIJ_AUTO_EXIT:-false}"
  eval "$(zellij setup --generate-auto-start zsh)"
fi


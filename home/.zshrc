# ~/.zshrc — zsh with autosuggestions + syntax highlighting, keeping Omarchy niceties.

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=32768
SAVEHIST=32768
setopt hist_ignore_all_dups hist_ignore_space share_history inc_append_history

# --- Completion (case-insensitive, menu select) ---
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- Keymap: жёстко emacs, никакого vi ---
# Без явного bindkey zsh выбирает раскладку по $VISUAL/$EDITOR. У нас EDITOR=nvim —
# в имени есть "vi", и zsh молча включает vi-режим, где ^? = vi-backward-delete-char:
# backspace отказывается стирать всё, что попало в буфер до входа в insert-режим,
# в том числе текст, вставленный из буфера обмена. Должно стоять до плагинов,
# чтобы autosuggestions / history-substring-search / fzf привязались к emacs.
bindkey -e
bindkey '^?' backward-delete-char        # Backspace — на случай, если vi-раскладка вернётся
bindkey '^H' backward-delete-char        # Ctrl+Backspace в части терминалов

# Home/End/Delete/Ctrl+стрелки zsh по умолчанию не привязывает вообще.
bindkey '^[[H'    beginning-of-line      # Home
bindkey '^[OH'    beginning-of-line      # Home (application mode)
bindkey '^[[F'    end-of-line            # End
bindkey '^[OF'    end-of-line            # End (application mode)
bindkey '^[[3~'   delete-char            # Delete
bindkey '^[[1;5C' forward-word           # Ctrl+Right
bindkey '^[[1;5D' backward-word          # Ctrl+Left

# --- Omarchy env vars + aliases (bash files, but mostly zsh-compatible) ---
for _f in envs aliases; do
  [[ -r ~/.local/share/omarchy/default/bash/$_f ]] && source ~/.local/share/omarchy/default/bash/$_f
done
unset _f

# --- Tool integrations (cross-shell) ---
command -v mise     >/dev/null && eval "$(mise activate zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v fzf      >/dev/null && source <(fzf --zsh)

# --- Plugins (syntax-highlighting MUST be sourced last) ---
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
_zp=/usr/share/zsh/plugins
[[ -r $_zp/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source $_zp/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r $_zp/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && source $_zp/zsh-history-substring-search/zsh-history-substring-search.zsh
[[ -r $_zp/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source $_zp/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unset _zp

# Up/Down search history by the prefix already typed
bindkey '^[[A' history-substring-search-up 2>/dev/null
bindkey '^[[B' history-substring-search-down 2>/dev/null

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section


# --- Тулчейн разработки (Rust/Java/Android) ---
[ -r ~/.config/devtools.env.sh ] && . ~/.config/devtools.env.sh

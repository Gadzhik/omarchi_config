# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# ble.sh — fish/zsh-like inline autosuggestions + syntax highlighting.
# Loaded here with --noattach, activated with ble-attach at the very end of this file.
for _blesh in "$HOME/.local/share/blesh/ble.sh" /usr/share/blesh/ble.sh; do
  [[ -f $_blesh ]] && { source "$_blesh" --noattach; break; }
done
unset _blesh

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# fzf: history search (Ctrl+R), file search (Ctrl+T), fuzzy path completion (**<Tab>)
eval "$(fzf --bash)"

# Activate ble.sh (must be the last line): enables the live autosuggestions.
[[ ${BLE_VERSION-} ]] && ble-attach

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section


# --- Тулчейн разработки (Rust/Java/Android) ---
[ -r ~/.config/devtools.env.sh ] && . ~/.config/devtools.env.sh

# Added by LM Studio CLI tool (lms)
export PATH="$PATH:/home/igadzhi/.lmstudio/bin"

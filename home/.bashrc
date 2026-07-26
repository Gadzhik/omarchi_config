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
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# fzf: history search (Ctrl+R), file search (Ctrl+T), fuzzy path completion (**<Tab>)
eval "$(fzf --bash)"

# Activate ble.sh (must be the last line): enables the live autosuggestions.
[[ ${BLE_VERSION-} ]] && ble-attach

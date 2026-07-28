# Cheat-sheet wallpaper

Source for `home/.config/omarchy/backgrounds/tokyo-night/vim-omarchy-neon.png` —
a neon Vim / LazyVim / Omarchy keybinding reference.

Regenerate after editing `vim-omarchy-neon.html`:

```bash
cd wallpaper
chromium --headless --disable-gpu --hide-scrollbars \
  --window-size=1920,1200 --force-device-scale-factor=1.6 \
  --screenshot=vim-omarchy-neon.png --virtual-time-budget=3000 \
  "file://$PWD/vim-omarchy-neon.html"

cp vim-omarchy-neon.png "../home/.config/omarchy/backgrounds/tokyo-night/"
cp vim-omarchy-neon.png "$HOME/.config/omarchy/backgrounds/tokyo-night/"
omarchy theme bg set "$HOME/.config/omarchy/backgrounds/tokyo-night/vim-omarchy-neon.png"
```

## Why those render flags

The page is laid out in **1920×1200 CSS pixels** — the logical size of this
display — and the 1.6 device scale factor renders it at the panel's native
3072×1920. Font sizes therefore mean the same thing on the wallpaper as they do
in any other window, instead of being shrunk by the display scale.

`padding-top` on `.page` is **34px**, which clears the 26px waybar (`height` in
`waybar/config.jsonc`, and what Hyprland reports as `reserved`) plus a small gap.
Change one and change the other.

## Content

Keybindings are transcribed from the installed sources, not from memory:

- **Vim** — plain Vim, valid anywhere.
- **LazyVim** — read out of `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/`
  (`config/keymaps.lua`, `plugins/lsp/init.lua`, `plugins/extras/editor/snacks_picker.lua`).
  Accurate for the LazyVim starter with the `neo-tree` extra; re-check after
  a `:Lazy update` that bumps LazyVim itself.
- **Omarchy** — merged from `~/.local/share/omarchy/default/hypr/bindings/`
  (`tiling-v2.conf`, `utilities.conf`, `media.conf`) and the personal overrides
  in `home/.config/hypr/bindings.conf`.

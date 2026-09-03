# Cheat-sheet wallpaper

Source for `home/.config/omarchy/backgrounds/tokyo-night/vim-omarchy-neon.png` —
a neon Vim / LazyVim / Omarchy keybinding reference.

Regenerate after editing `vim-omarchy-neon.html`:

The PNG lives in three places — keep them in sync or they drift apart:
the repo root (previewed on git frontends), the deploy tree under `home/`
(what `install.sh` copies), and the live system.

```bash
cd wallpaper
chromium --headless --disable-gpu --hide-scrollbars \
  --window-size=1920,1200 --force-device-scale-factor=1.6 \
  --screenshot=../vim-omarchy-neon.png --virtual-time-budget=3000 \
  "file://$PWD/vim-omarchy-neon.html"

cd ..
cp vim-omarchy-neon.png home/.config/omarchy/backgrounds/tokyo-night/
cp vim-omarchy-neon.png "$HOME/.config/omarchy/backgrounds/tokyo-night/"
omarchy theme bg set "$HOME/.config/omarchy/backgrounds/tokyo-night/vim-omarchy-neon.png"
```

## Why those render flags

The page is laid out in **1920×1200 CSS pixels** — the logical size of this
display — and the 1.6 device scale factor renders it at the panel's native
3072×1920. Font sizes therefore mean the same thing on the wallpaper as they do
in any other window, instead of being shrunk by the display scale.

`padding-top` on `.page` is **34px**, which clears the 26px top bar plus a small
gap. waybar is gone in Omarchy 4, but the quickshell bar reserves the same 26px —
check with `hyprctl monitors -j | jq '.[0].reserved'` before changing it.

## Content

Keybindings are transcribed from the installed sources, not from memory:

- **Vim** — plain Vim, valid anywhere.
- **LazyVim** — read out of `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/`
  (`config/keymaps.lua`, `plugins/lsp/init.lua`, `plugins/extras/editor/snacks_picker.lua`).
  Accurate for the LazyVim starter with the `neo-tree` extra; re-check after
  a `:Lazy update` that bumps LazyVim itself.
- **Omarchy** — verified against the live compositor rather than the sources:
  `hyprctl binds -j` is the truth, since Omarchy 4 defaults
  (`/usr/share/omarchy/default/hypr/bindings/*.lua`) and the personal overrides in
  `home/.config/hypr/bindings.lua` both feed it. Re-check after an Omarchy upgrade.

## Fitting the layout

The page is `overflow:hidden` at a fixed 1920×1200 and `section{break-inside:avoid}`,
so the Omarchy card's two flowed columns cannot spill — content that does not fit is
silently **clipped**, not scrolled. Two budgets, both found the hard way:

- **~87 rows** across the card's six sections — that is the observed ceiling, with
  the right column ending a hair above the card edge. 88 rows overflowed back when
  the media section was still present; the true limit is height, not row count, so
  re-render and look before trusting either number.
- **38 characters** for key + description on one row. `.row` is `white-space:nowrap`,
  so a longer row widens its column past the card and gets cut at the right edge.

Combine related bindings on one row (`SUPER ^ O / ^ P` → `меню / питание`) rather than
adding rows. Always re-render and *look at the PNG* before committing.

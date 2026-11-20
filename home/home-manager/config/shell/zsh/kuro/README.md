# Kuro Af Zsh theme

`themes/kuro-af.zsh-theme` is a two-line, af-magic-inspired prompt. It shows the
current directory, Git branch, exit status, clock, and a visible Distrobox or
container label. Prompt colors come from Kuro's generated palette.

The startup files in this directory are the maintained copies. In `~/.zshenv`,
source the environment, and in `~/.zshrc`, source the config:

```zsh
source "$HOME/.config/zsh/zshenv"
source "$HOME/.config/zsh/zshrc"
```

Kuro regenerates `~/.cache/kuro/zsh-colors.zsh` whenever its palette changes;
the theme reloads those colors on every prompt. Startup loads completion,
FZF, suggestions, directory jumping and shell helpers, then the prompt, with
syntax highlighting last so it can wrap ZLE widgets.

The setup uses `zoxide` automatically when installed. Without it, `z` and `zi`
use a small frecency database under `~/.config/zsh/cache`. FZF provides Ctrl-R
history search, Ctrl-T file search, Alt-C directory search, plus `fcd` and
`fopen`. History suggestions appear as dim ghost text; Right accepts them at
the end of the command and Ctrl-Space accepts the full suggestion. Native ZLE
syntax highlighting and suggestions work without downloading plugin code, and
system-installed zsh-autosuggestions / zsh-syntax-highlighting are preferred
when available.

`kurobox` lists configured Distroboxes with no arguments and enters a named box
with `kurobox <name>`.

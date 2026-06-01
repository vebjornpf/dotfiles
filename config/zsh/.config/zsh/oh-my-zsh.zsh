export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="catppuccin"
CATPPUCCIN_FLAVOR="macchiato"
plugins=(gradle zsh-autosuggestions zsh-syntax-highlighting vi-mode)
# Keep completion cache in XDG cache dir to avoid scattered .zcompdump files.
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
mkdir -p "${ZSH_COMPDUMP%/*}"

# Change cursor shape on mode switch (block in normal, line in insert)
VI_MODE_SET_CURSOR=true

source $ZSH/oh-my-zsh.sh

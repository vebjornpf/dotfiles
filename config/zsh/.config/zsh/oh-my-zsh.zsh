export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(gradle zsh-autosuggestions zsh-syntax-highlighting)
# Keep completion cache in XDG cache dir to avoid scattered .zcompdump files.
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
mkdir -p "${ZSH_COMPDUMP%/*}"
source $ZSH/oh-my-zsh.sh
    

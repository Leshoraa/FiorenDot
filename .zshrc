# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"
export PROMPT_EOL_MARK=""
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export PATH="$HOME/.local/bin:$PATH"

# Disable compfix check for instantaneous startup (~320ms saved)
export ZSH_DISABLE_COMPFIX="true"

# Starship manages prompt, disable OMZ theme loading overhead
ZSH_THEME=""

plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias tty-clock='tty-clock -c -C 4 -f "%a %b %d"'
alias cty-clock='tty-clock -s -S -b -B -n'
alias pipes.sh='pipes.sh -r 800'
alias discord='DISCORDO_TOKEN="" discordo'
alias tf='yazi'
alias ard-ide='arduino-ide --no-sandbox --ozone-platform=x11 --disable-gpu'
alias kitty='kitty -1'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
alias config='/usr/bin/git --git-dir=/home/hyprlan/.cfg/ --work-tree=/home/hyprlan'

# Initialize Starship prompt
eval "$(starship init zsh)"

export PATH=$PATH:/home/fioren/.spicetify

# NVM Optimization: Put active node in PATH directly for instant execution, lazy-load nvm on demand
export NVM_DIR="$HOME/.nvm"
for node_ver in "$NVM_DIR"/versions/node/*(N/); do
    export PATH="$node_ver/bin:$PATH"
    break
done

nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}

# Run fastfetch at the very end so that shell is 100% loaded and starship prompt appears instantly
fastfetch

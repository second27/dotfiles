export LANG=ko_KR.UTF-8

set custom prompt
setopt PROMPT_SUBST
autoload -U promptinit
promptinit
prompt grb

# Initialize completion
autoload -U compinit
compinit

# Add paths
export PATH=/usr/local/sbin:/usr/local/bin:${PATH}
export PATH="$HOME/bin:$PATH"

# Colorize terminal
export TERM='xterm-256color'
alias ls='ls -G'
alias ll='ls -lG'
alias ea="/Applications/Emacs.app/Contents/MacOS/Emacs"
alias em="/Applications/Emacs.app/Contents/MacOS/Emacs -nw"
alias emacs="/Applications/Emacs.app/Contents/MacOS/Emacs -nw"
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
export GREP_OPTIONS="--color"

# Nicer history
export HISTSIZE=100000
export HISTFILE="$HOME/.history"
export SAVEHIST=$HISTSIZE

# Use vim as the editor
export EDITOR=emacs
# GNU Screen sets -o vi if EDITOR=vi, so we have to force it back.
set -o emacs

# Use C-x C-e to edit the current command line
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# By default, zsh considers many characters part of a word (e.g., _ and -).
# Narrow that down to allow easier skipping through words via M-f and M-b.
export WORDCHARS='*?[]~&;!$%^<>'

# Highlight search results in ack.
export ACK_COLOR_MATCH='red'

# Aliases
alias r=rails
alias t="script/test $*"
alias f="script/features $*"
function mcd() { mkdir -p $1 && cd $1 }
function cdf() { cd *$1*/ } # stolen from @topfunky

# Activate the closest virtualenv by looking in parent directories.
activate_virtualenv() {
		if [ -f env/bin/activate ]; then . env/bin/activate;
		elif [ -f ../env/bin/activate ]; then . ../env/bin/activate;
		elif [ -f ../../env/bin/activate ]; then . ../../env/bin/activate;
		elif [ -f ../../../env/bin/activate ]; then . ../../../env/bin/activate;
		fi
}

# Find the directory of the named Python module.
python_module_dir () {
		echo "$(python -c "import os.path as _, ${1}; \
				print _.dirname(_.realpath(${1}.__file__[:-1]))"
				)"
}

# By @ieure; copied from https://gist.github.com/1474072
#
# It finds a file, looking up through parent directories until it finds one.
# Use it like this:
#
#   $ ls .tmux.conf
#   ls: .tmux.conf: No such file or directory
#
#   $ ls `up .tmux.conf`
#   /Users/grb/.tmux.conf
#
#   $ cat `up .tmux.conf`
#   set -g default-terminal "screen-256color"
#
function up()
{
		local DIR=$PWD
		local TARGET=$1
		while [ ! -e $DIR/$TARGET -a $DIR != "/" ]; do
				DIR=$(dirname $DIR)
		done
		test $DIR != "/" && echo $DIR/$TARGET
}

export NODE_PATH=/usr/local/lib/node_modules
export NODE_NO_READLINE=1

# Initialize RVM
PATH=$PATH:$HOME/.rvm/bin
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# rbenv
# export PATH="$HOME/.rbenv/bin:$PATH"
# export SHELL=`which zsh` zsh
# eval "$(rbenv init -)"
# export GTAGSLABEL=rtags

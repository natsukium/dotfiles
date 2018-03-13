#
# ~/.bashrc
#

[[ $- != *i* ]] && return

colors() {
	local fgc bgc vals seq0

	printf "Color escapes are %s\n" '\e[${value};...;${value}m'
	printf "Values 30..37 are \e[33mforeground colors\e[m\n"
	printf "Values 40..47 are \e[43mbackground colors\e[m\n"
	printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

	# foreground colors
	for fgc in {30..37}; do
		# background colors
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf "  %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
		done
		echo; echo
	done
}

[[ -f ~/.extend.bashrc ]] && . ~/.extend.bashrc

[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion

# colors
if [ -x /usr/bin/dircolors ]; then
    if [ -f $HOME/.dircolors ]; then
        eval $(dircolors ~/.dircolors)
    fi

    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias la='ls -alF'
alias ll='ls -A'
alias l='ls -CF'

if type vim >/dev/null 2>&1; then
    alias vi='vim'
fi

# prohibit Ctrl-s
stty stop undef

# Ctrl-w
stty werase undef
bind "\C-w":unix-filename-rubout

# set PS1
PS1="\u@\h: \w\n$ "

# TMUX
if type tmux >/dev/null 2>&1; then
    function is_exists() { type "$1" >/dev/null 2>&1; return $?; }
    function is_osx() { [[ $OSTYPE == darwin* ]]; }
    function is_screen_running() { [ ! -z "$STY" ]; }
    function is_tmux_runnning() { [ ! -z "$TMUX" ]; }
    function is_screen_or_tmux_running() { is_screen_running || is_tmux_runnning; }
    function shell_has_started_interactively() { [ ! -z "$PS1" ]; }
    function is_ssh_running() { [ ! -z "$SSH_CONECTION" ]; }

    function tmux_automatically_attach_session()
    {
        if is_screen_or_tmux_running; then
            ! is_exists 'tmux' && return 1

            if is_tmux_runnning; then
                echo -e "\e[34;1m" "      _/_/      _/_/_/ _/_/_/_/_/                          " "\e[m"
                echo -e "\e[34;1m" "   _/    _/      _/       _/    _/_/   _/  _/_/ _/_/_/ _/_/" "\e[m"
                echo -e "\e[34;1m" "  _/_/_/_/      _/       _/  _/_/_/_/ _/_/     _/   _/   _/" "\e[m"
                echo -e "\e[34;1m" " _/    _/      _/       _/  _/       _/       _/   _/   _/ " "\e[m"
                echo -e "\e[34;1m" "_/    _/ _/ _/_/_/  _/ _/    _/_/_/ _/       _/   _/   _/  " "\e[m"
            elif is_screen_running; then
                echo "This is on screen."
            fi
        else
            if shell_has_started_interactively && ! is_ssh_running; then
                if ! is_exists 'tmux'; then
                    echo 'Error: tmux command not found' 2>&1
                    return 1
                fi

                if tmux has-session >/dev/null 2>&1 && tmux list-sessions | grep -qE '.*]$'; then
                    # detached session exists
                    tmux list-sessions
                    echo -n "Tmux: attach? (y/N/num) "
                    read
                    if [[ "$REPLY" =~ ^[Yy]$ ]] || [[ "$REPLY" == '' ]]; then
                        tmux attach-session
                        if [ $? -eq 0 ]; then
                            echo "$(tmux -V) attached session"
                            return 0
                        fi
                    elif [[ "$REPLY" =~ ^[0-9]+$ ]]; then
                        tmux attach -t "$REPLY"
                        if [ $? -eq 0 ]; then
                            echo "$(tmux -V) attached session"
                            return 0
                        fi
                    fi
                fi

                if is_osx && is_exists 'reattach-to-user-namespace'; then
                    # on OS X force tmux's default command
                    # to spawn a shell in the user's namespace
                    tmux_config=$(cat $HOME/.tmux.conf <(echo 'set-option -g default-command "reattach-to-user-namespace -l $SHELL"'))
                    tmux -f <(echo "$tmux_config") new-session && echo "$(tmux -V) created new session supported OS X"
               else
#                    tmux new-session \; split-window -h -d && echo "tmux created new session"

                   tmux new-session && echo "tmux created new session"
               fi
            fi
        fi
    }
    tmux_automatically_attach_session
fi

[[ -f ~/.bashenv ]] && . ~/.bashenv

if type fish >/dev/null 2>&1; then
    exec fish
fi

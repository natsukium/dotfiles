#
# ~/.bashrc
#

export LANG=ja_JP.UTF-8
export LC_TYPE=ja_JP.UTF-8

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_RUNTIME_DIR=$HOME/.run

[[ $- != *i* ]] && return

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

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

# prohibit Ctrl-s
stty stop undef

# Ctrl-w
stty werase undef
bind "\C-w":unix-filename-rubout

# set PS1
PS1="\u@\h: \w\n$ "

# TMUX
alias tmux='tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf'

if type tmux >/dev/null 2>&1; then
    function is_exists() {
        type "$1" >/dev/null 2>&1
        return $?
    }
    function is_osx() { [[ $OSTYPE == darwin* ]]; }
    function is_screen_running() { [ ! -z "$STY" ]; }
    function is_tmux_runnning() { [ ! -z "$TMUX" ]; }
    function is_screen_or_tmux_running() { is_screen_running || is_tmux_runnning; }
    function shell_has_started_interactively() { [ ! -z "$PS1" ]; }
    function is_ssh_running() { [ ! -z "$SSH_CONECTION" ]; }

    function tmux_automatically_attach_session() {
        if is_screen_or_tmux_running; then
            ! is_exists 'tmux' && return 1

            if is_tmux_runnning; then
                echo "Siro is so cute!"
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

# Common Environment
[[ -f $XDG_CONFIG_HOME/bash/environ ]] && . $XDG_CONFIG_HOME/bash/environ

[[ -f ~/.bashenv ]] && . ~/.bashenv

if type fish >/dev/null 2>&1; then
    exec fish
fi

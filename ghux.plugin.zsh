#!/usr/bin/env zsh

# set -eu
#
# if you dont need user id in tmux session name, set this.
# GHUX_WITHOUT_USER_NAME=1
: ${GHUX_WITHOUT_USER_NAME:=0}

# if you want to going dotfiles dir with ghux, add this option
# GHUX_DOTFILES_OPTION=1
: ${GHUX_DOTFILES_OPTION:=0}

# set ghux aliases path
: ${GHUX_ALIASES_PATH:="$HOME/.ghux_aliases"}


function print_usage() {
    cat << EOL
You dont have ghq or fzf.
$ go get github.com/motemen/ghq
$ brew install fzf
EOL
}

function ghux() {
    if ! (type ghq &> /dev/null && type fzf &> /dev/null); then
        print_usage
        exit 1
    fi


    local tmux_list=$(tmux list-session)
    local ghq_list=$(ghq list)
    # [[ $GHUX_DOTFILES_OPTION == 0 ]] && ghq_list="* dotfiles"

    local file
    file="$GHUX_ALIASES_PATH"
    if [[ -n $1 ]];then
    # if [[ `echo $ghux_aliases |grep $1` ]];then
        project_dir="~/dotfiles"
        project_name="dotfiles"
#     elif [[ -n $1 ]];then
#         if ![[ $tmux_list =~ $1 ]]; then
#             [[ -n $CURSOR ]] && zle clear-screen
#             return 1
#         else
#             
#         fi
    else
        local project_dir
        # if [[ -n $1 ]];then
        if [[ `echo $ghux_aliases |grep $1` ]];then
            project_dir=$(echo $ghq_list|fzf --preview="" -q $1)
        else
            project_dir=$(echo $ghq_list|fzf --preview="")
        fi

        if [[ -z $project_dir ]]; then
            [[ -n $CURSOR ]] && zle clear-screen
            return 1
        fi

        project_dir=$(ghq root)/$project_dir
        local project_name
        # session名にusernameを含めるかどうか
        if [[ $GHUX_WITHOUT_USER_NAME == 0 ]] ; then
            project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s/%s", $1,$2}' |rev)
        else;
            project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s", $1}' |rev)
        fi
    fi

    # if you in tmux sesion
    [[ -n $TMUX ]] && in_tmux=0

    # tmuxに既にfzfで選択したプロジェクトのセッションが存在するかどうか
    if [[ ! `echo $tmux_list | grep "$project_name"` ]]; then
        (cd $project_dir && TMUX=; tmux new-session -ds $project_name) > /dev/null
    fi

    if [[ -n $in_tmux ]] ; then
        tmux switch-client -t $project_name
    else;
        tmux attach-session -t $project_name
    fi
    [[ -n $CURSOR ]] && zle redisplay || clear

}

zle -N ghux

#!/usr/bin/env zsh

# set -eu
#
# if you dont need user id in tmux session name, set this.
# GHUX_WITHOUT_USER_NAME=1

GHUX_WITHOUT_USER_NAME=0


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


    local project_dir=$(ghq list|fzf)
    if [[ -z $project_dir ]]; then
        [[ -n $CURSOR ]] && zle clear-screen
        return 1
    fi

    local ghq_root=$(ghq root)
    local project_dir=$(ghq root)/$project_dir


    local project_name
    # session名にusernameを含めるかどうか
    if [[ $GHUX_WITHOUT_USER_NAME == 0 ]] ; then
        project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s/%s", $1,$2}' |rev)
    else;
        project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s", $1}' |rev)
    fi

    # if you in tmux sesion
    [[ -n $TMUX ]] && in_tmux=0

    # tmuxに既にfzfで選択したプロジェクトのセッションが存在するかどうか
    is_session=$(tmux list-sessions | awk -v project_name="$project_name" '{if($1 == project_name":"){print 0}}')
    if [[ -z $is_session ]]; then
        (cd $project_dir && TMUX=; tmux new-session -ds $project_name)
    fi

    if [[ -n $in_tmux ]] ; then
        tmux switch-client -t $project_name
    else;
        tmux attach-session -t $project_name
    fi
    [[ -n $CURSOR ]] && zle redisplay

}

zle -N ghux

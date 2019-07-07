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
or detach tmux session
EOL
}

function ghux() {
    if ! (type ghq &> /dev/null && type fzf &> /dev/null); then
        print_usage
        exit 1
    fi

    project_dir=$(ghq list|fzf)
    [[ -z $project_dir ]] && echo "Error: you should choice directry." >&2 && return 1

    ghq_root=$(ghq root)
    project_dir=$ghq_root/$project_dir


    # session名にusernameを含めるかどうか
    if [[ $GHUX_WITHOUT_USER_NAME == 0 ]] ; then
        project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s/%s", $1,$2}' |rev)
    else;
        project_name=$( echo $project_dir |rev | awk -F \/ '{printf "%s", $1}' |rev)
    fi

    # if you in tmux ssesion
    [[ -n $TMUX ]] && in_tmux=0 ; echo "in_tmux: $in_tmux"

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
}


#!/usr/bin/env zsh
#
# if you want to going dotfiles dir with ghux, add this option
# GHUX_DOTFILES_OPTION=1
: ${GHUX_DOTFILES_OPTION:=0}

# set ghux aliases path
: ${GHUX_ALIASES_PATH:="$HOME/.ghux_aliases"}
: ${GHUX_RECENT_PATH:="${XDG_CACHE_HOME:-$HOME/.cache}/ghux/recent"}
: ${GHUX_RECENT_LIMIT:=10}

function print_usage() {
    cat << EOL
You dont have ghq or fzf.
$ go get github.com/motemen/ghq
$ brew install fzf
EOL
}

function ghux_recent_init() {
    command mkdir -p "${GHUX_RECENT_PATH:h}" 2>/dev/null || return 1
    touch "$GHUX_RECENT_PATH" 2>/dev/null || return 1
    return 0
}

function ghux_recent_load_map() {
    typeset -gA GHUX_RECENT_RANK
    GHUX_RECENT_RANK=()

    [[ -f "$GHUX_RECENT_PATH" ]] || return 0

    local rank=1 r_type r_key map_key
    while IFS=$'\t' read -r r_type r_key; do
        [[ -z "$r_type" || -z "$r_key" ]] && continue
        map_key="$r_type"$'\t'"$r_key"
        [[ -n "${GHUX_RECENT_RANK[$map_key]}" ]] && continue
        GHUX_RECENT_RANK[$map_key]=$rank
        (( rank++ ))
    done < "$GHUX_RECENT_PATH"
}

function ghux_recent_latest() {
    typeset -g GHUX_RECENT_LATEST_TYPE GHUX_RECENT_LATEST_KEY
    GHUX_RECENT_LATEST_TYPE=""
    GHUX_RECENT_LATEST_KEY=""

    [[ -f "$GHUX_RECENT_PATH" ]] || return 0

    local r_type r_key
    while IFS=$'\t' read -r r_type r_key; do
        [[ -z "$r_type" || -z "$r_key" ]] && continue
        GHUX_RECENT_LATEST_TYPE="$r_type"
        GHUX_RECENT_LATEST_KEY="$r_key"
        return 0
    done < "$GHUX_RECENT_PATH"
}

# input pairs format: key<TAB>display
function ghux_filter_pairs_excluding_latest() {
    local item_type="$1"
    local pairs="$2"

    if [[ "$item_type" != "$GHUX_RECENT_LATEST_TYPE" || -z "$GHUX_RECENT_LATEST_KEY" ]]; then
        print -r -- "$pairs"
        return 0
    fi

    local key display
    while IFS=$'\t' read -r key display; do
        [[ -z "$key" || -z "$display" ]] && continue
        [[ "$key" == "$GHUX_RECENT_LATEST_KEY" ]] && continue
        print -r -- "$key"$'\t'"$display"
    done <<< "$pairs"
}

function ghux_recent_record() {
    local r_type="$1"
    local r_key="$2"

    case "$r_type" in
        repo|alias|session|window) ;;
        *) return 0 ;;
    esac

    [[ -z "$r_key" ]] && return 0
    ghux_recent_init || return 0

    local tmp_file
    tmp_file=$(mktemp "${TMPDIR:-/tmp}/ghux_recent_XXXXXX") || return 0

    {
        print -r -- "$r_type"$'\t'"$r_key"
        awk -F $'\t' -v t="$r_type" -v k="$r_key" '!(NF >= 2 && $1 == t && $2 == k) && NF >= 2 { print $0 }' "$GHUX_RECENT_PATH" 2>/dev/null
    } | head -n "$GHUX_RECENT_LIMIT" >| "$tmp_file"

    command mv "$tmp_file" "$GHUX_RECENT_PATH" 2>/dev/null || {
        command cp "$tmp_file" "$GHUX_RECENT_PATH" 2>/dev/null
        /bin/rm -f "$tmp_file"
    }
}

# input pairs format: key<TAB>display
function ghux_sort_pairs_by_recent() {
    local item_type="$1"
    local pairs="$2"

    local -a prioritized
    local -a normal
    local key display map_key rank

    while IFS=$'\t' read -r key display; do
        [[ -z "$key" || -z "$display" ]] && continue
        map_key="$item_type"$'\t'"$key"
        rank="${GHUX_RECENT_RANK[$map_key]}"
        if [[ -n "$rank" ]]; then
            prioritized+=("$rank"$'\t'"$key"$'\t'"$display")
        else
            normal+=("$key"$'\t'"$display")
        fi
    done <<< "$pairs"

    local result=""

    if (( ${#prioritized[@]} > 0 )); then
        local sorted_prioritized
        sorted_prioritized=$(printf '%s\n' "${prioritized[@]}" | sort -n -t $'\t' -k1,1 | cut -f2-)
        result="$sorted_prioritized"
    fi

    if (( ${#normal[@]} > 0 )); then
        local normal_text
        normal_text=$(printf '%s\n' "${normal[@]}")
        if [[ -n "$result" ]]; then
            result+=$'\n'"$normal_text"
        else
            result="$normal_text"
        fi
    fi

    print -r -- "$result"
}

# output pairs format: key<TAB>display
function ghux_collect_tmux_session_pairs() {
    [[ -n "$TMUX" ]] || return 0

    local current_session
    current_session=$(tmux display-message -p '#S' 2>/dev/null)

    tmux list-sessions -F '#S' 2>/dev/null | while IFS= read -r sess; do
        [[ -z "$sess" ]] && continue
        [[ "$sess" == "$current_session" ]] && continue
        print -r -- "$sess"$'\t'$'\033[32m[session]\033[0m '"$sess"
    done
}

# output pairs format: key<TAB>display
function ghux_collect_tmux_window_pairs() {
    [[ -n "$TMUX" ]] || return 0

    local current_window
    current_window=$(tmux display-message -p '#S:#I' 2>/dev/null)

    tmux list-windows -a -F $'#S\t#I\t#{pane_current_path}\t#W' 2>/dev/null | while IFS=$'\t' read -r sess idx pane_path win_name; do
        [[ -z "$sess" || -z "$idx" ]] && continue
        [[ "${sess}:${idx}" == "$current_window" ]] && continue

        local branch="" git_path="$pane_path/.git"
        if [[ -d "$git_path" ]]; then
            local head
            head=$(<"$git_path/HEAD")
            [[ "$head" == ref:* ]] && branch="${head#ref: refs/heads/}"
        elif [[ -f "$git_path" ]]; then
            local gitdir
            gitdir=$(<"$git_path")
            gitdir="${gitdir#gitdir: }"
            if [[ -f "$gitdir/HEAD" ]]; then
                local head
                head=$(<"$gitdir/HEAD")
                [[ "$head" == ref:* ]] && branch="${head#ref: refs/heads/}"
            fi
        fi

        local key="${sess}:${idx}"
        local title="${branch:-$win_name}"
        print -r -- "$key"$'\t'$'\033[36m[window]\033[0m '"${sess}:${idx}: ${title}"
    done
}

# output pairs format: key<TAB>display
function ghux_collect_alias_pairs() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    awk -F ',' 'NF >= 1 && $1 != "" { printf "%s\t\033[33m[alias]\033[0m %s\n", $1, $1 }' "$file"
}

# output pairs format: key<TAB>display
function ghux_collect_repo_pairs() {
    if ! (type ghq &> /dev/null); then
        return 0
    fi

    ghq list 2>/dev/null | awk '{ printf "%s\t\033[34m[repo]\033[0m %s\n", $0, $0 }'
}

function ghux_pairs_to_entries() {
    local item_type="$1"
    local pairs="$2"

    local key display
    while IFS=$'\t' read -r key display; do
        [[ -z "$key" || -z "$display" ]] && continue
        print -r -- "$display"$'\t'"$item_type"$'\t'"$key"
    done <<< "$pairs"
}

function ghux_sort_entries_by_recent() {
    local entries="$1"

    local -a prioritized
    local -a normal
    local display item_type key map_key rank
    local idx=0

    while IFS=$'\t' read -r display item_type key; do
        [[ -z "$display" || -z "$item_type" || -z "$key" ]] && continue
        (( idx++ ))
        map_key="$item_type"$'\t'"$key"
        rank="${GHUX_RECENT_RANK[$map_key]}"
        if [[ -n "$rank" ]]; then
            prioritized+=("$rank"$'\t'"$idx"$'\t'"$display"$'\t'"$item_type"$'\t'"$key")
        else
            normal+=("$display"$'\t'"$item_type"$'\t'"$key")
        fi
    done <<< "$entries"

    local result=""

    if (( ${#prioritized[@]} > 0 )); then
        local sorted_prioritized
        sorted_prioritized=$(printf '%s\n' "${prioritized[@]}" | sort -n -t $'\t' -k1,1 -k2,2 | cut -f3-)
        result="$sorted_prioritized"
    fi

    if (( ${#normal[@]} > 0 )); then
        local normal_text
        normal_text=$(printf '%s\n' "${normal[@]}")
        if [[ -n "$result" ]]; then
            result+=$'\n'"$normal_text"
        else
            result="$normal_text"
        fi
    fi

    print -r -- "$result"
}

function ghux() {
    if ! (type fzf &> /dev/null); then
        print_usage
        return 1
    fi

    touch "$GHUX_ALIASES_PATH"
    ghux_recent_init >/dev/null 2>&1

    local file="$GHUX_ALIASES_PATH"
    local project_alias
    local project_name
    local project_dir

    if [[ -n "$1" ]]; then
        local alias_line
        alias_line=$(awk -F ',' -v a="$1" '$1 == a { print; exit }' "$file")
        if [[ -n "$alias_line" ]]; then
            IFS=',' read -r project_alias project_name project_dir <<< "$alias_line"
            project_name="${project_name/./}"
            ghux_recent_record "alias" "$project_alias"
        fi
    fi

    if [[ -z "$project_name" || -z "$project_dir" ]]; then
        setopt local_options no_monitor
        ghux_recent_load_map
        ghux_recent_latest

        local tmux_session_pairs tmux_window_pairs alias_pairs
        tmux_session_pairs=$(ghux_collect_tmux_session_pairs)
        tmux_window_pairs=$(ghux_collect_tmux_window_pairs)
        alias_pairs=$(ghux_collect_alias_pairs "$file")

        tmux_session_pairs=$(ghux_filter_pairs_excluding_latest "session" "$tmux_session_pairs")
        tmux_window_pairs=$(ghux_filter_pairs_excluding_latest "window" "$tmux_window_pairs")
        alias_pairs=$(ghux_filter_pairs_excluding_latest "alias" "$alias_pairs")

        local -a initial_entries_arr
        local line

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            initial_entries_arr+=("$line")
        done <<< "$(ghux_pairs_to_entries "session" "$tmux_session_pairs")"

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            initial_entries_arr+=("$line")
        done <<< "$(ghux_pairs_to_entries "window" "$tmux_window_pairs")"

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            initial_entries_arr+=("$line")
        done <<< "$(ghux_pairs_to_entries "alias" "$alias_pairs")"

        if (( ${#initial_entries_arr[@]} > 0 )); then
            local initial_entries_text
            initial_entries_text=$(printf '%s\n' "${initial_entries_arr[@]}")
            initial_entries_text=$(ghux_sort_entries_by_recent "$initial_entries_text")
            if [[ -n "$initial_entries_text" ]]; then
                initial_entries_arr=("${(@f)initial_entries_text}")
            else
                initial_entries_arr=()
            fi
        fi

        local full_tmp
        full_tmp=$(mktemp "${TMPDIR:-/tmp}/ghux_full_XXXXXX") || return 1

        (
            local repo_pairs
            repo_pairs=$(ghux_collect_repo_pairs)
            repo_pairs=$(ghux_filter_pairs_excluding_latest "repo" "$repo_pairs")

            local -a full_entries_arr
            full_entries_arr=("${initial_entries_arr[@]}")

            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                full_entries_arr+=("$line")
            done <<< "$(ghux_pairs_to_entries "repo" "$repo_pairs")"

            if (( ${#full_entries_arr[@]} > 0 )); then
                local full_entries_text
                full_entries_text=$(printf '%s\n' "${full_entries_arr[@]}")
                full_entries_text=$(ghux_sort_entries_by_recent "$full_entries_text")
                if [[ -n "$full_entries_text" ]]; then
                    printf '%s\n' "${(@f)full_entries_text}" >| "$full_tmp"
                else
                    : >| "$full_tmp"
                fi
            else
                : >| "$full_tmp"
            fi
        ) &
        local full_pid=$!

        local reload_cmd
        reload_cmd="while [ ! -s '$full_tmp' ]; do if ! kill -0 $full_pid 2>/dev/null; then break; fi; sleep 0.05; done; cat '$full_tmp' 2>/dev/null"

        local selected
        if (( ${#initial_entries_arr[@]} > 0 )); then
            selected=$(printf '%s\n' "${initial_entries_arr[@]}" | fzf \
                --ansi \
                --tabstop=12 \
                --prompt='ghux> ' \
                --delimiter=$'\t' \
                --with-nth=1 \
                --bind "start:reload:$reload_cmd")
        else
            selected=$(printf '' | fzf \
                --ansi \
                --tabstop=12 \
                --prompt='ghux> ' \
                --delimiter=$'\t' \
                --with-nth=1 \
                --bind "start:reload:$reload_cmd")
        fi

        wait $full_pid 2>/dev/null
        /bin/rm -f "$full_tmp"

        if [[ -z "$selected" ]]; then
            [[ -n "$CURSOR" ]] && zle redisplay
            return 1
        fi

        local selected_type selected_key
        selected_type=$(print -r -- "$selected" | cut -f2)
        selected_key=$(print -r -- "$selected" | cut -f3-)

        case "$selected_type" in
            session)
                ghux_recent_record "session" "$selected_key"
                if [[ -n "$TMUX" ]]; then
                    tmux switch-client -t "$selected_key"
                else
                    tmux attach-session -t "$selected_key"
                fi
                return 0
                ;;
            window)
                ghux_recent_record "window" "$selected_key"
                local target_session="${selected_key%%:*}"
                local target_index="${selected_key#*:}"
                if [[ -n "$TMUX" ]]; then
                    tmux switch-client -t "$target_session"
                    tmux select-window -t "$target_session:$target_index"
                else
                    tmux attach-session -t "$target_session"
                    tmux select-window -t "$target_session:$target_index"
                fi
                return 0
                ;;
            alias)
                local alias_line
                alias_line=$(awk -F ',' -v a="$selected_key" '$1 == a { print; exit }' "$file")
                if [[ -z "$alias_line" ]]; then
                    return 1
                fi
                IFS=',' read -r project_alias project_name project_dir <<< "$alias_line"
                project_name="${project_name/./}"
                ghux_recent_record "alias" "$project_alias"
                ;;
            repo)
                if ! (type ghq &> /dev/null); then
                    return 1
                fi
                project_dir="$(ghq root)/$selected_key"
                project_name="${selected_key##*/}"
                project_name="${project_name/./}"
                ghux_recent_record "repo" "$selected_key"
                ;;
            *)
                return 1
                ;;
        esac
    fi

    [[ -z "$project_name" || -z "$project_dir" ]] && return 1

    # if you in tmux sesion
    local in_tmux
    [[ -n "$TMUX" ]] && in_tmux=0 || in_tmux=1

    # tmuxに既に選択したプロジェクトのセッションが存在するかどうか
    if ! tmux has-session -t "$project_name" 2>/dev/null; then
        local resolved_dir
        resolved_dir=$(eval echo "${project_dir}")
        (cd "$resolved_dir" && TMUX=; tmux new-session -ds "$project_name") > /dev/null 2>&1
    fi

    if [[ $in_tmux == 0 ]]; then
        if [[ -n "$CONTEXT" ]]; then
            BUFFER="tmux switch-client -t $project_name" && zle accept-line && zle redisplay
        else
            tmux switch-client -t "$project_name"
        fi
    else
        if [[ -n "$CONTEXT" ]]; then
            BUFFER="tmux attach-session -t $project_name" && zle accept-line && zle redisplay
        else
            tmux attach-session -t "$project_name"
        fi
    fi
}

zle -N ghux

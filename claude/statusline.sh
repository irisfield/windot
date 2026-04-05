#!/bin/bash
# Claude Code Status Line

set -f  # disable globbing

# ===== Config =====
SHOW_GIT=true           # git branch, dirty status, ahead/behind
SHOW_TOKENS=true        # token usage bar
SHOW_THINKING=true      # extended thinking indicator
SHOW_RATE_LIMITS=true   # 5h / 7d rate limit bars
BRANCH_MAX_LEN=28       # truncate branch names longer than this
GIT_CACHE_SECS=10       # seconds to cache git status (git diff is slow on large repos)
TOKEN_BAR_WIDTH=8       # width of token progress bar

# Terminal width detection.
# Claude Code pipes JSON into stdin, so stty on /dev/tty fails (no controlling
# terminal on stdin). We try stderr (fd 2) instead — it stays connected to the
# real TTY even when stdin is redirected.
if [ "${TERM_WIDTH:-0}" -le 0 ] 2>/dev/null; then
    if [ "${COLUMNS:-0}" -gt 0 ] 2>/dev/null; then
        TERM_WIDTH=$COLUMNS
    else
        _w=$(stty size <&2 2>/dev/null | awk '{print $2}')
        if [ "${_w:-0}" -le 0 ] 2>/dev/null; then
            _w=$(stty size </dev/tty 2>/dev/null | awk '{print $2}')
        fi
        [ "${_w:-0}" -gt 0 ] 2>/dev/null && TERM_WIDTH=$_w || TERM_WIDTH=220
        unset _w
    fi
fi

input=$(cat)
[ -z "$input" ] && printf "Claude" && exit 0

mkdir -p /tmp/claude

# ===== Dependency check =====
_missing_deps=""
for _cmd in jq awk git stat date cksum; do
    command -v "$_cmd" >/dev/null 2>&1 || _missing_deps="${_missing_deps:+$_missing_deps, }$_cmd"
done
# jq is required — fall back to minimal output immediately
if ! command -v jq >/dev/null 2>&1; then
    printf "\033[38;2;235;87;87mmissing deps: %s\033[0m" "$_missing_deps"
    exit 0
fi

# ===== Colors =====
blue='\033[38;2;97;175;239m'
orange='\033[38;2;255;176;85m'
amber='\033[38;2;229;192;123m'
green='\033[38;2;80;200;120m'
cyan='\033[38;2;86;182;194m'
red='\033[38;2;235;87;87m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
magenta='\033[38;2;198;120;221m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}│${reset} "

# ===== Helpers =====

format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

truncate_str() {
    local str="$1" max="$2"
    [ "${#str}" -gt "$max" ] \
        && printf "%s…" "${str:0:$((max-1))}" \
        || printf "%s" "$str"
}

# Colored progress bar using block chars
build_bar() {
    local pct=$1 width=$2
    [ "$pct" -lt 0 ] 2>/dev/null && pct=0
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100
    local filled=$(( (pct * width + 50) / 100 ))
    local empty=$(( width - filled ))
    local bar_color
    if   [ "$pct" -ge 90 ]; then bar_color="$red"
    elif [ "$pct" -ge 70 ]; then bar_color="$yellow"
    elif [ "$pct" -ge 50 ]; then bar_color="$orange"
    else                         bar_color="$green"
    fi
    local f="" e=""
    for ((i=0; i<filled; i++)); do f+="█"; done
    for ((i=0; i<empty;  i++)); do e+="░"; done
    printf "${bar_color}${f}${dim}${e}${reset}"
}

# ===== Git info with per-directory caching =====
get_git_info() {
    local dir="$1"
    [ -z "$dir" ] && return

    # Stable cache key per directory path
    local dir_hash
    dir_hash=$(printf '%s' "$dir" | cksum | awk '{print $1}')
    local cache_file="/tmp/claude/git-${dir_hash}"

    local needs_refresh=true
    if [ -f "$cache_file" ]; then
        local mtime now age
        mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
        now=$(date +%s)
        age=$(( now - mtime ))
        [ "$age" -lt "$GIT_CACHE_SECS" ] && needs_refresh=false
    fi

    if $needs_refresh; then
        # Branch name (or short hash for detached HEAD)
        local branch
        branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)
        if [ -z "$branch" ]; then
            branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
            if [ -z "$branch" ]; then
                : > "$cache_file"   # not a git repo — write empty cache
                return
            fi
            branch="(${branch})"
        fi

        # Dirty: any staged or unstaged changes
        local dirty=""
        [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && dirty="dirty"

        # Ahead / behind upstream (skip if no upstream set)
        local ahead=0 behind=0
        local upstream
        upstream=$(git -C "$dir" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)
        if [ -n "$upstream" ]; then
            local ab
            ab=$(git -C "$dir" rev-list --left-right --count "HEAD...${upstream}" 2>/dev/null)
            ahead=$(echo "$ab"  | awk '{print $1}')
            behind=$(echo "$ab" | awk '{print $2}')
        fi

        # Tab-delimited cache (branch names can't contain tabs per git spec)
        printf '%s\t%s\t%s\t%s' "$branch" "$dirty" "${ahead:-0}" "${behind:-0}" > "$cache_file"
    fi

    cat "$cache_file" 2>/dev/null
}

# ===== Format epoch reset time =====
format_reset_time() {
    local epoch="$1" style="$2"
    [ -z "$epoch" ] || [ "$epoch" = "null" ] || [ "$epoch" = "0" ] && return
    case "$style" in
        time)
            date -d "@$epoch" +"%l:%M%P"  2>/dev/null | sed 's/^ //' ||
            date -j -r "$epoch" +"%l:%M%p" 2>/dev/null | sed 's/^ //' | tr '[:upper:]' '[:lower:]'
            ;;
        datetime)
            date -d "@$epoch" +"%b %-d, %l:%M%P"  2>/dev/null | sed 's/  / /g; s/^ //' ||
            date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]'
            ;;
    esac
}

# ===== Extract JSON =====
_jq() { echo "$input" | jq -r "$1" | tr -d '\r'; }

model_name=$(_jq '.model.display_name // "Claude"')
cwd=$(_jq '.cwd // empty')
cost_usd=$(_jq '.cost.total_cost_usd // empty')

size=$(_jq '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

input_tokens=$(_jq '.context_window.current_usage.input_tokens // 0')
cache_create=$(_jq '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(_jq '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)
pct_used=$(( size > 0 ? current * 100 / size : 0 ))

thinking_on=false
settings_path="$HOME/.claude/settings.json"
if [ -f "$settings_path" ]; then
    thinking_val=$(jq -r '.alwaysThinkingEnabled // false' "$settings_path" 2>/dev/null | tr -d '\r')
    [ "$thinking_val" = "true" ] && thinking_on=true
fi

# ===== Adaptive width tiers =====
#
# Tiers (tuned so each tier's max output fits within its min width):
#
#  full    (≥120): CWD, ahead/behind, "◆ thinking", 5h+7d+reset, cost
#  wide    (90–119): ahead/behind, "◆ thinking", 5h+reset, cost
#  split   (70–89):  ahead/behind, "◆" symbol, 5h bar, cost
#  narrow  (<70):  short model + branch + token only
#
if   [ "$TERM_WIDTH" -ge 120 ] 2>/dev/null; then width_tier="full"
elif [ "$TERM_WIDTH" -ge 90  ] 2>/dev/null; then width_tier="wide"
elif [ "$TERM_WIDTH" -ge 70  ] 2>/dev/null; then width_tier="split"
else                                              width_tier="narrow"
fi

# Shorten model name for tight spaces
short_model() {
    case "$1" in
        *Opus*)   echo "Opus" ;;
        *Sonnet*) echo "Sonnet" ;;
        *Haiku*)  echo "Haiku" ;;
        *)        echo "$1" | awk '{print $NF}' ;;   # last word
    esac
}

# ===== Build output =====
out=""

# Model — color by family
model_color="$blue"
case "$model_name" in
    *Opus*)  model_color="$amber" ;;
    *Haiku*) model_color="$cyan"  ;;
esac

display_model="$model_name"
[ "$width_tier" = "narrow" ] && display_model=$(short_model "$model_name")
out+="${model_color}${display_model}${reset}"

# CWD — full tier only (branch name gives enough context below that)
if [ "$width_tier" = "full" ] && [ -n "$cwd" ]; then
    # Handle both Unix (/) and Windows (\) path separators
    display_dir="${cwd##*/}"
    display_dir="${display_dir##*\\}"
    out+="${sep}${dim}${display_dir}${reset}"
fi

# Git branch + dirty + ahead/behind
if $SHOW_GIT && [ -n "$cwd" ]; then
    git_info=$(get_git_info "$cwd")
    if [ -n "$git_info" ]; then
        IFS=$'\t' read -r g_branch g_dirty g_ahead g_behind <<< "$git_info"

        # Progressively tighten branch truncation
        local_max="$BRANCH_MAX_LEN"
        [ "$width_tier" = "wide"   ] && local_max=24
        [ "$width_tier" = "split"  ] && local_max=18
        [ "$width_tier" = "narrow" ] && local_max=12
        g_branch_display=$(truncate_str "$g_branch" "$local_max")

        out+="${sep}${dim}⎇${reset} ${magenta}${g_branch_display}${reset}"

        if [ "$g_dirty" = "dirty" ]; then
            out+=" ${red}✗${reset}"
        else
            out+=" ${green}✔${reset}"
        fi

        # Ahead/behind: shown in all tiers except narrow (only if non-zero)
        if [ "$width_tier" != "narrow" ]; then
            [ "${g_ahead:-0}"  -gt 0 ] && out+=" ${green}↑${g_ahead}${reset}"
            [ "${g_behind:-0}" -gt 0 ] && out+=" ${orange}↓${g_behind}${reset}"
        fi
    fi
fi

# Token bar
if $SHOW_TOKENS; then
    bar_w="$TOKEN_BAR_WIDTH"
    [ "$width_tier" = "wide"   ] && bar_w=6
    [ "$width_tier" = "split"  ] && bar_w=5
    [ "$width_tier" = "narrow" ] && bar_w=4
    token_bar=$(build_bar "$pct_used" "$bar_w")
    out+="${sep}${token_bar} ${orange}${used_tokens}${dim}/${reset}${white}${total_tokens}${reset} ${dim}${pct_used}%${reset}"
fi

# Thinking:
#   full/wide  → "◆ thinking" / "◇ thinking"  (label)
#   split      → "◆" / "◇"                    (symbol only, saves ~9 chars)
#   narrow     → hidden
if $SHOW_THINKING && [ "$width_tier" != "narrow" ]; then
    out+="${sep}"
    if $thinking_on; then
        if [ "$width_tier" = "split" ]; then out+="${amber}◆${reset}"
        else out+="${amber}◆ thinking${reset}"; fi
    else
        if [ "$width_tier" = "split" ]; then out+="${dim}◇${reset}"
        else out+="${dim}◇ thinking${reset}"; fi
    fi
fi

# Session cost — wide/full only
if [ -n "$cost_usd" ] && [ "$width_tier" = "wide" -o "$width_tier" = "full" ]; then
    cost_fmt=$(printf '%.2f' "$cost_usd" 2>/dev/null)
    [ -n "$cost_fmt" ] && out+="${sep}${dim}\$${cost_fmt}${reset}"
fi

# ===== Rate limits (from input JSON) =====
# shown in full/wide/split; hidden only in narrow
if $SHOW_RATE_LIMITS && [ "$width_tier" != "narrow" ]; then
    if echo "$input" | jq -e '.rate_limits' >/dev/null 2>&1; then
        bar_width=6
        [ "$width_tier" = "split" ] && bar_width=4

        five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0' | tr -d '\r' | awk '{printf "%.0f", $1}')
        five_hour_reset_epoch=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // 0' | tr -d '\r')
        five_hour_bar=$(build_bar "$five_hour_pct" "$bar_width")
        out+="${sep}${dim}5h${reset} ${five_hour_bar} ${cyan}${five_hour_pct}%${reset}"
        # Reset time: full and wide only (not split — saves ~12 chars)
        if [ "$width_tier" = "full" ] || [ "$width_tier" = "wide" ]; then
            five_hour_reset=$(format_reset_time "$five_hour_reset_epoch" "time")
            [ -n "$five_hour_reset" ] && out+=" ${dim}↺ ${five_hour_reset}${reset}"
        fi

        # 7d bar + reset: full only
        if [ "$width_tier" = "full" ]; then
            seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0' | tr -d '\r' | awk '{printf "%.0f", $1}')
            seven_day_reset_epoch=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // 0' | tr -d '\r')
            seven_day_reset=$(format_reset_time "$seven_day_reset_epoch" "datetime")
            seven_day_bar=$(build_bar "$seven_day_pct" "$bar_width")
            out+="${sep}${dim}7d${reset} ${seven_day_bar} ${cyan}${seven_day_pct}%${reset}"
            [ -n "$seven_day_reset" ] && out+=" ${dim}↺ ${seven_day_reset}${reset}"
        fi
    fi
fi

# Append missing-dep warning (non-jq tools)
if [ -n "$_missing_deps" ]; then
    out+="${sep}\033[38;2;235;87;87m⚠ missing: ${_missing_deps}\033[0m"
fi

printf "%b" "$out"
exit 0

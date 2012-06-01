# tmux attach or new-session integration for zsh.

## Copyright (c) 2011, Frank Terbeck <ft@bewatermyfriend.org>
##
## Permission to use, copy, modify, and/or distribute this software for any
## purpose with or without fee is hereby granted, provided that the above
## copyright notice and this permission notice appear in all copies.
##
## THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
## WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
## MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
## ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
## WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
## ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
## OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

emulate -L zsh
setopt {extended,null}_glob warncreateglobal

local -A opt
zparseopts -D -M -A opt d x

: "${opt[@]}"
if (( ARGC != 1 )); then
    cat <<EOF
usage: ta [OPTION(s)] <session-name>

\`session-name' may be an existing or a new session name. If it is an
existing session's name, the session is attached to; otherwise, a new
session is registered with tmux and then attached to.

Options:
  -d    When attaching to an existing session, pass the \`-d' option
        to tmux, which will detach any other clients attached to the
        session.
  -x    Do *not* call "tmux attach" using \`exec', but without. So,
        when present and the tmux session is detached from again,
        control will be picked up be the (still existing) parent shell
        again.

Use tab completion to complete option characters and names of existing
sessions.
EOF
    if [[ -z $TMUX ]]; then
        return 1
    else
        print
    fi
fi

if [[ -n $TMUX ]]; then
    cat <<EOF
Environment variable \`\$TMUX' set. \`ta' will not attempt to nest.
EOF
    return 1
fi

local tmp session
local -i rc

session=$1
shift

# This works around an epoll bug on Linux. Looks silly, but works.
tmux has-session -t $session |& read tmp
rc=${pipestatus[1]}

if (( rc != 0 )); then
    tmux new-session -d -s $session ||
        { printf 'Failed to created session `%s'\''\n' $session
          return 1; }
fi

local -a tmux_options

tmux_options=(attach-session -t $session)
(( ${+opt[-d]} )) && tmux_options+=(-d)

local EXEC=exec
(( ${+opt[-x]} )) && EXEC=

${=EXEC} tmux "${tmux_options[@]}"

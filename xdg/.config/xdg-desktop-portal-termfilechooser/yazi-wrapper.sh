#!/usr/bin/env sh
# Custom Yazi wrapper for xdg-desktop-portal-termfilechooser.
#
# Important behavior:
# - Selecting/opening a file or directory writes it to the chooser file.
# - Quitting/closing Yazi writes nothing, so the portal treats the request as cancelled.
# - We intentionally do NOT use --cwd-file for directory selection, because that makes
#   closing Yazi return the current directory to apps like VS Code instead of cancelling.

set -e

if [ "$6" -ge 4 ]; then
    set -x
fi

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

cmd="yazi"
termcmd="${TERMCMD:-kitty --title termfilechooser -e}"

# Start with an empty chooser output. If Yazi is closed without selecting/opening
# anything, this remains empty and the portal cancels the request.
: > "$out"

if [ "$save" = "1" ]; then
    # Save a file. Opening the destination in Yazi confirms the save target.
    set -- --chooser-file="$out" "$path"
elif [ "$directory" = "1" ]; then
    # Select a directory. Do not pass --cwd-file; closing Yazi must cancel.
    set -- --chooser-file="$out" "$path"
elif [ "$multiple" = "1" ]; then
    # Select multiple files.
    set -- --chooser-file="$out" "$path"
else
    # Select one file.
    set -- --chooser-file="$out" "$path"
fi

command="$termcmd $cmd"
for arg in "$@"; do
    escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
    command="$command \"$escaped\""
done

# Return success even when no file was selected. The portal decides cancellation
# from the empty chooser file; a non-zero exit would be reported as a launcher error.
sh -c "$command" || true

# Be explicit: empty means cancel/no selection.
if [ ! -s "$out" ]; then
    : > "$out"
fi

exit 0

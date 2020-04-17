#!/bin/bash
# Run as if it was called from cron, that is to say:
#  * with a modified environment
#  * with a specific shell, which may or may not be bash
#  * without an attached input terminal
#  * in a non-interactive shell

function usage(){
    echo "$0 - Run a script or a command as it would be in a cron job, then display its output"
    echo "Usage:"
    echo "   $0 [command | script]"
}

if [ "$1" == "-h" -o "$1" == "--help" ]; then
    usage
    exit 0
fi

if [ $(whoami) != "root" ]; then
    echo "Only root is supported at the moment"
    exit 1
fi

# This file should contain the cron environment.
cron_env="/root/cron-env"
if [ ! -f "$cron_env" ]; then
    echo "Unable to find $cron_env"
    echo "To generate it, run \"/usr/bin/env > /root/cron-env\" as a cron job"
    exit 0
fi

# It will be a nightmare to expand "$@" inside a shell -c argument.
# Let's rather generate a string where we manually expand-and-quote the arguments
env_string="/usr/bin/env -i "
for envi in $(cat "$cron_env"); do
   env_string="${env_string} $envi "
done

cmd_string=""
for arg in "$@"; do
    cmd_string="${cmd_string} \"${arg}\" "
done

# Which shell should we use?
the_shell=$(grep -E "^SHELL=" /root/cron-env | sed 's/SHELL=//')
echo "Running with $the_shell the following command: $cmd_string"


# Let's route the output in a file
# and do not provide any input (so that the command is executed without an attached terminal)
so=$(mktemp "/tmp/fakecron.out.XXXX")
se=$(mktemp "/tmp/fakecron.err.XXXX")
"$the_shell" -c "$env_string $cmd_string" >"$so" 2>"$se" < /dev/null

echo -e "Done. Here is \033[1mstdout\033[0m:"
cat "$so"
echo -e "Done. Here is \033[1mstderr\033[0m:"
cat "$se"
rm "$so" "$se"
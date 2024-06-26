#!/bin/bash

addresses=""
hostfile=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -l) login="$2"; shift 2;;

    --login=*) login="${1#*=}"; shift 1;;
    --login) echo "$1 requires an argument" >&2; exit 1;;

    -h) hostfile="$2"; shift 2;;

    --host=*) hostfile="${1#*=}"; shift 1;;
    --host) echo "$1 requires an argument" >&2; exit 1;;

    -*) echo "unknown option: $1" >&2; exit 1;;
    *) addresses=$(echo "$addresses $1"); shift 1;;
  esac
done

if [ ! -z "$hostfile" ] && [ -e "$hostfile" ]; then
    addresses="$addresses $(cat $hostfile)"
fi
echo "Connecting to $addresses..."

num_addresses=$(echo "$addresses" | wc -w)
if [ "$num_addresses" -eq 0 ]; then
    echo "Need at least one hostname"
    exit 2
fi

ssh_command () {
    addr="$1"
    if [[ "$login" != "" && ! "$addr" =~ "@" ]]; then
        addr=$(echo $login@$addr)
    fi
    echo "ssh $addr"
}

tmux new-window -n "ssh"

i=0
for addr in $(echo "$addresses"); do
    if [ "$i" -gt 0 ]; then
        tmux split-window -t ssh
        tmux select-layout -t ssh tiled
    fi
    tmux send-keys -t ssh "$(ssh_command $addr)" C-m
    i=$((i+1))
done

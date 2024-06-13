#!/bin/zsh
# cluster ssh tool for zsh users
. "$(dirname $0)/options.zsh"
setUsage "Cluster SSH tool for zsh\nusage: $(basename $0) [options] [host1] [host2] ..."
addOption -s  --session_name  dest=SESSION_NAME   default="csshx"   help="tmux session name"
addOption -w  --window_name   dest=WINDOW_NAME    default="ssh"     help="tmux window name"
addOption -u  --user          dest=LOGIN_USER     default="${USER}" help="login as USER"
addOption -l  --hostlist_file dest=HOSTLIST_FILE  default=""        help="file containing list of hosts"
addOption -k  --sshkey_file   dest=SSHKEY_FILE    default=""        help="ssh private key if required"
parseOptions "$@"

if [ -n "${HOSTLIST_FILE}" ] && [ -e "${HOSTLIST_FILE}" ]; then
  HOSTS=($(cat "${HOSTLIST_FILE}"))
fi
HOSTS="${optArgv[@]} ${HOSTS}"

if [ -n "${SSHKEY_FILE}" ]; then
  SSHKEY="-i ${SSHKEY_FILE}"
else
  SSHKEY=""
fi

HOST_COUNT=$(echo "${HOSTS}" | wc -w)
if [ "${HOST_COUNT}" -eq 0 ]; then
  echo "at least one hostname is required"
  exit 1
fi

function ssh_command() {
  HOST="$1"
  COMMAND="ssh ${SSHKEY} ${LOGIN_USER}@${HOST}"
  echo "${COMMAND}"
}

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
    echo "tmux session ${SESSION_NAME} already exists. attaching to the session..."
else
    echo "creating new session: ${SESSION_NAME}"
    tmux new-session -d -s "${SESSION_NAME}"
fi
tmux attach -t "${SESSION_NAME}"

tmux new-window -n "${WINDOW_NAME}"
for HOST in ${HOSTS}; do
  if [ "${i}" -gt 0 ]; then
    tmux split-window -t "${SESSION_NAME}:${WINDOW_NAME}"
    tmux select-layout -t "${SESSION_NAME}:${WINDOW_NAME}" tiled
  fi
  tmux send-keys -t "${SESSION_NAME}:${WINDOW_NAME}" "$(ssh_command ${HOST})" C-m
  i=$((i+1))
done

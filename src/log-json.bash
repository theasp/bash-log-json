__LOG_JSON__HOSTNAME=$(hostname -f)
__LOG_JSON__ID=0
__LOG_JSON__FINISHED=0
__LOG_JSON__TTY=$(tty)
__LOG_JSON__SESSION=$(uuidgen)
__LOG_JSON__LOG_DIR=~/.bash_log/${__LOG_JSON__HOSTNAME}/
__LOG_JSON__FILE=${__LOG_JSON__LOG_DIR}/${__LOG_JSON__SESSION}.json

function __log_json__session_event_jq {
  jq -c -n \
     --arg session "$__LOG_JSON__SESSION" \
     --arg hostname "$__LOG_JSON__HOSTNAME" \
     --arg pid "$$" \
     --arg tty "$__LOG_JSON__TTY" \
     --arg level "$SHLVL" \
     '{"type": "session",
       "time": now,
       "session": $session,
       "hostname": $hostname,
       "pid": $pid,
       "tty": $tty,
       "level": $level}'
}

function __log_json__start_event_jq {
  jq -c -n \
     --arg session "$__LOG_JSON__SESSION" \
     --arg hostname "$__LOG_JSON__HOSTNAME" \
     --arg id "$__LOG_JSON__ID" \
     --arg cmd "$__LOG_JSON__CMD" \
     '{"type": "start",
       "time": now,
       "session": $session,
       "hostname": $hostname,
       "id": $id,
       "cmd": $cmd}'
}

function __log_json__end_event_jq {
  jq -c -n \
     --arg session "$__LOG_JSON__SESSION" \
     --arg hostname "$__LOG_JSON__HOSTNAME" \
     --arg id "$__LOG_JSON__ID" \
     --arg rc "$__LOG_JSON__RC" \
     --arg cmd "$__LOG_JSON__CMD" \
     '{"type": "end",
       "time": now,
       "session": $session,
       "hostname": $hostname,
       "id": $id,
       "cmd": $cmd,
       "rc": $rc}' >> $__LOG_JSON__FILE
}


function __log_json__preexec {
  __LOG_JSON__CMD="$1"
  __LOG_JSON__ID=$(( __LOG_JSON__ID + 1 ))
  __log_json__start_event_jq >> $__LOG_JSON__FILE
}

function __log_json__precmd {
  __LOG_JSON__RC=$?
  if [[ $__LOG_JSON__FINISHED != $__LOG_JSON__ID ]]; then
    __LOG_JSON__FINISHED=$__LOG_JSON__ID
    __log_json__end_event_jq >> $__LOG_JSON__FILE
  fi
}

(umask 0077; mkdir -p ${__LOG_JSON__LOG_DIR})
precmd_functions+=(__log_json__precmd)
preexec_functions+=(__log_json__preexec)
__log_json__session_event_jq >> $__LOG_JSON__FILE

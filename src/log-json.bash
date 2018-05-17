function __log_json__get_engine {
  if which jq 2>&1 > /dev/null; then
    echo jq
  elif (which perl; perl -MJSON::PP -e true) >/dev/null 2>&1; then
    echo perl
  fi
}

function __log_json__session_init {
  __LOG_JSON__ENGINE=$(__log_json__get_engine)
  if [[ $__LOG_JSON__ENGINE ]]; then
    if [[ $__LOG_JSON__SESSION_INIT != true ]]; then
      __LOG_JSON__HOSTNAME=$(hostname -f)
      __LOG_JSON__ID=0
      __LOG_JSON__FINISHED=0
      __LOG_JSON__TTY=$(tty)
      __LOG_JSON__SESSION=$(uuidgen)
      __LOG_JSON__LOG_DIR=~/.bash_log/${__LOG_JSON__HOSTNAME}/
      __LOG_JSON__FILE=${__LOG_JSON__LOG_DIR}/${__LOG_JSON__SESSION}.json
      __LOG_JSON__SESSION_INIT=true

      (umask 0077; mkdir -p ${__LOG_JSON__LOG_DIR})
      case $__LOG_JSON__ENGINE in
        jq)   __log_json__session_event_jq >> $__LOG_JSON__FILE ;;
        perl) __log_json__session_event_perl >> $__LOG_JSON__FILE ;;
      esac
      precmd_functions+=(__log_json__precmd)
      preexec_functions+=(__log_json__preexec)
    fi
  else
    echo "Unable to intialize log-json, need jq or perl installed" 1>&2
  fi
}

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
       "pid": $pid|fromjson,
       "tty": $tty,
       "level": $level|fromjson}'
}

function __log_json__session_event_perl {
  perl - \
       "$__LOG_JSON__SESSION" \
       "$__LOG_JSON__HOSTNAME" \
       "$$" \
       "$__LOG_JSON__TTY" \
       "$SHLVL" <<-'EOF'
use Time::HiRes qw(time);
use JSON::PP;
($session, $hostname, $pid, $tty, $level) = @ARGV;
$data = {type => session,
         time => time(),
         session => $session,
         hostname => $hostname,
         pid => int($pid),
         tty => $tty,
         level => int($level)};

print(encode_json($data) . "\n");
EOF
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
       "id": $id|fromjson,
       "cmd": $cmd}'
}

function __log_json__start_event_perl {
  perl -\
       "$__LOG_JSON__SESSION" \
       "$__LOG_JSON__HOSTNAME" \
       "$__LOG_JSON__ID" \
       "$__LOG_JSON__CMD" <<-'EOF'
use Time::HiRes qw(time);
use JSON::PP;
($session, $hostname, $id, $cmd) = @ARGV;
$data = {type => session,
         time => time(),
         session => $session,
         hostname => $hostname,
         id => int($id),
         cmd => $cmd};

print(encode_json($data) . "\n")
EOF
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
       "id": $id|fromjson,
       "cmd": $cmd,
       "rc": $rc|fromjson}' >> $__LOG_JSON__FILE
}

function __log_json__end_event_perl {
  perl - \
       "$__LOG_JSON__SESSION" \
       "$__LOG_JSON__HOSTNAME" \
       "$__LOG_JSON__ID" \
       "$__LOG_JSON__CMD" \
       "$__LOG_JSON__RC" <<-'EOF'
use Time::HiRes qw(time);
use JSON::PP;
($session, $hostname, $id, $cmd, $rc) = @ARGV;
$data = {type => session,
         time => time(),
         session => $session,
         hostname => $hostname,
         id => int($id),
         cmd => $cmd};

print(encode_json($data) . "\n")
EOF
}

function __log_json__preexec {
  __LOG_JSON__CMD="$1"
  __LOG_JSON__ID=$(( __LOG_JSON__ID + 1 ))
  case $__LOG_JSON__ENGINE in
    jq)   __log_json__start_event_jq >> $__LOG_JSON__FILE ;;
    perl) __log_json__start_event_perl >> $__LOG_JSON__FILE ;;
  esac
}

function __log_json__precmd {
  __LOG_JSON__RC=$?
  if [[ $__LOG_JSON__FINISHED != $__LOG_JSON__ID ]]; then
    __LOG_JSON__FINISHED=$__LOG_JSON__ID
    case $__LOG_JSON__ENGINE in
      jq)   __log_json__end_event_jq >> $__LOG_JSON__FILE ;;
      perl) __log_json__end_event_perl >> $__LOG_JSON__FILE ;;
    esac
  fi
}

__log_json__session_init

# echo "Perl"
# time {
#   for i in $(seq 1000); do
#     __log_json__session_event_perl > /dev/null
#   done
# }

# echo "JQ"
# time {
#   for i in $(seq 1000); do
#     __log_json__session_event_jq > /dev/null
#   done
# }

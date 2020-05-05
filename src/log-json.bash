function __log_json__get_engine {
  if which jq >/dev/null 2>&1; then
    echo jq
  elif python3- <<<"import json; json.dumps(None)" >/dev/null 2>&1; then
    echo python3
  elif python2 - <<<"import json; json.dumps(None)" >/dev/null 2>&1; then
    echo python2
  elif perl -MJSON::PP -e true >/dev/null 2>&1; then
    echo perl
  fi
}

function __log_json__uuidgen {
  if [[ -e /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  elif [[ -e /compat/linux/proc/sys/kernel/random/uuid ]]; then
    cat /compat/linux/proc/sys/kernel/random/uuid
  elif which uuidgen >/dev/null 2>&1; then
    uuidgen
  elif which python2 >/dev/null 2>&1; then
    python2 -c 'import uuid; print uuid.uuid4()'
  elif which python3 >/dev/null 2>&1; then
    python3 -c 'import uuid; print uuid.uuid4()'
  else
    echo $RANDOM
  fi
}


function __log_json__session_init {
  __LOG_JSON__ENGINE=$(__log_json__get_engine)
  if [[ $__LOG_JSON__ENGINE ]]; then
    if [[ $__LOG_JSON__SESSION_INIT != true ]]; then
      __LOG_JSON__USERNAME=$(id -un)
      __LOG_JSON__HOSTNAME=$(hostname -f)
      __LOG_JSON__ID=0
      __LOG_JSON__FINISHED=0
      __LOG_JSON__TTY=$(tty)
      __LOG_JSON__SESSION=$(__log_json__uuidgen)
      __LOG_JSON__LOG_DIR=~/.bash_log/${__LOG_JSON__HOSTNAME}/
      __LOG_JSON__FILE=${__LOG_JSON__LOG_DIR}/${__LOG_JSON__SESSION}.json
      __LOG_JSON__SESSION_INIT=true

      (umask 0077; mkdir -p ${__LOG_JSON__LOG_DIR})
      case $__LOG_JSON__ENGINE in
        jq)   __log_json__session_event_jq   >> $__LOG_JSON__FILE ;;
        perl) __log_json__session_event_perl >> $__LOG_JSON__FILE ;;
      esac

      precmd_functions+=(__log_json__precmd)
      preexec_functions+=(__log_json__preexec)
    fi
  else
    echo "Unable to intialize log-json, need jq, python or perl installed" 1>&2
  fi
}

function __log_json__session_event_jq {
  jq -c -n \
     --arg session "$__LOG_JSON__SESSION" \
     --arg username "$__LOG_JSON__USERNAME" \
     --arg hostname "$__LOG_JSON__HOSTNAME" \
     --arg pid "$$" \
     --arg tty "$__LOG_JSON__TTY" \
     --arg level "$SHLVL" \
     '{"type": "session",
       "timestamp": now,
       "session": $session,
       "username": $username,
       "hostname": $hostname,
       "pid": $pid|fromjson,
       "tty": $tty,
       "level": $level|fromjson}'
}

function __log_json__session_event_python2 {
  python2 - "$__LOG_JSON__SESSION" "$__LOG_J0ON__USERNAME" "$__LOG_JSON__HOSTNAME" "$$" "$__LOG_JSON__TTY" "$SHLVL" <<"EOF"
import json
import time
import sys
data = {}
data['type'] = 'session'
data['timestamp'] = time.time()
data['session'] = sys.argv[1]
data['username'] = sys.argv[2]
data['hostname'] = sys.argv[3]
data['pid'] = int(sys.argv[4])
data['tty'] = sys.argv[5]
data['level'] = int(sys.argv[6])
print json.dumps(data, separators=(',',':'))
EOF
}

function __log_json__session_event_python3 {
  python3 - "$__LOG_JSON__SESSION" "$__LOG_J0ON__USERNAME" "$__LOG_JSON__HOSTNAME" "$$" "$__LOG_JSON__TTY" "$SHLVL" <<"EOF"
import json
import time
import sys
data = {}
data['type'] = 'session'
data['timestamp'] = time.time()
data['session'] = sys.argv[1]
data['username'] = sys.argv[2]
data['hostname'] = sys.argv[3]
data['pid'] = int(sys.argv[4])
data['tty'] = sys.argv[5]
data['level'] = int(sys.argv[6])
print(json.dumps(data, separators=(',',':')))
EOF
}


function __log_json__session_event_perl {
  perl - \
       "$__LOG_JSON__SESSION" \
       "$__LOG_JSON__USERNAME" \
       "$__LOG_JSON__HOSTNAME" \
       "$$" \
       "$__LOG_JSON__TTY" \
       "$SHLVL" <<-'EOF'
use Time::HiRes qw(time);
use JSON::PP;
($session, $username, $hostname, $pid, $tty, $level) = @ARGV;
$data = {type => session,
         timestamp => time(),
         session => $session,
         username => $username,
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
     --arg username "$__LOG_JSON__USERNAME" \
     --arg hostname "$__LOG_JSON__HOSTNAME" \
     --arg id "$__LOG_JSON__ID" \
     --arg cmd "$__LOG_JSON__CMD" \
     '{"type": "start",
       "timestamp": now,
       "session": $session,
       "username": $username,
       "hostname": $hostname,
       "id": $id|fromjson,
       "cmd": $cmd}'
}

function __log_json__start_event_python2 {
  python2 - "$__LOG_JSON__SESSION" "$__LOG_JSON__USERNAME" "$__LOG_JSON__HOSTNAME" "$__LOG_JSON__ID" "$__LOG_JSON__CMD" <<"EOF"
import json
import time
import sys
data = {}
data['type'] = 'start'
data['timestamp'] = time.time()
data['session'] = sys.argv[1]
data['username'] = sys.argv[2]
data['hostname'] = sys.argv[3]
data['id'] = int(sys.argv[4])
data['cmd'] = sys.argv[5]
print json.dumps(data, separators=(',',':'))
EOF
}


function __log_json__start_event_python3 {
  python3 - "$__LOG_JSON__SESSION" "$__LOG_JSON__USERNAME" "$__LOG_JSON__HOSTNAME" "$__LOG_JSON__ID" "$__LOG_JSON__CMD" <<"EOF"
import json
import time
import sys
data = {}
data['type'] = 'start'
data['timestamp'] = time.time()
data['session'] = sys.argv[1]
data['username'] = sys.argv[2]
data['hostname'] = sys.argv[3]
data['id'] = int(sys.argv[4])
data['cmd'] = sys.argv[5]
print(json.dumps(data, separators=(',',':')))
EOF
}


function __log_json__start_event_perl {
  perl -\
       "$__LOG_JSON__SESSION" \
       "$__LOG_JSON__USERNAME" \
       "$__LOG_JSON__HOSTNAME" \
       "$__LOG_JSON__ID" \
       "$__LOG_JSON__CMD" <<-'EOF'
use Time::HiRes qw(time);
use JSON::PP;
($session, $username, $hostname, $id, $cmd) = @ARGV;
$data = {type => session,
         timestamp => time(),
         session => $session,
         username => $username,
         hostname => $hostname,
         id => int($id),
         cmd => $cmd};

print(encode_json($data) . "\n")
EOF
}

function __log_json__end_event_jq {
  jq -c -n \
     --arg session "$__LOG_JSON__SESSION" \
     --arg username "$__LOG_JSON__USERNAME" \
     --arg hostname "$__LOG_JSON__HOSTNAME" \
     --arg id "$__LOG_JSON__ID" \
     --arg rc "$__LOG_JSON__RC" \
     --arg cmd "$__LOG_JSON__CMD" \
     '{"type": "end",
       "timestamp": now,
       "session": $session,
       "username": $username,
       "hostname": $hostname,
       "id": $id|fromjson,
       "cmd": $cmd,
       "rc": $rc|fromjson}' >> $__LOG_JSON__FILE
}

function __log_json__end_event_python2 {
  python2 - "$__LOG_JSON__SESSION" "$__LOG_JSON__USERNAME" "$__LOG_JSON__HOSTNAME" "$__LOG_JSON__ID" "$__LOG_JSON__CMD" "$__LOG_JSON__RC" <<"EOF"
import json
import time
import sys
data = {}
data['type'] = 'stop'
data['timestamp'] = time.time()
data['session'] = sys.argv[1]
data['username'] = sys.argv[2]
data['hostname'] = sys.argv[3]
data['id'] = int(sys.argv[4])
data['cmd'] = sys.argv[5]
data['rc'] = int(sys.argv[6])
print json.dumps(data, separators=(',',':'))
EOF
}

function __log_json__end_event_python3 {
  python3 - "$__LOG_JSON__SESSION" "$__LOG_JSON__USERNAME" "$__LOG_JSON__HOSTNAME" "$__LOG_JSON__ID" "$__LOG_JSON__CMD" "$__LOG_JSON__RC" <<"EOF"
import json
import time
import sys
data = {}
data['type'] = 'stop'
data['timestamp'] = time.time()
data['session'] = sys.argv[1]
data['username'] = sys.argv[2]
data['hostname'] = sys.argv[3]
data['id'] = int(sys.argv[4])
data['cmd'] = sys.argv[5]
data['rc'] = int(sys.argv[6])
print(json.dumps(data, separators=(',',':')))
EOF
}

function __log_json__end_event_perl {
  perl - \
       "$__LOG_JSON__SESSION" \
       "$__LOG_JSON__USERNAME" \
       "$__LOG_JSON__HOSTNAME" \
       "$__LOG_JSON__ID" \
       "$__LOG_JSON__CMD" \
       "$__LOG_JSON__RC" <<-'EOF'
use Time::HiRes qw(time);
use JSON::PP;
($session, $username, $hostname, $id, $cmd, $rc) = @ARGV;
$data = {type => session,
         timestamp => timestamp(),
         session => $session,
         username => $username,
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
    jq)      __log_json__start_event_jq      >> $__LOG_JSON__FILE ;;
    python2) __log_json__start_event_python2 >> $__LOG_JSON__FILE ;;
    python3) __log_json__start_event_python3 >> $__LOG_JSON__FILE ;;
    perl)    __log_json__start_event_perl    >> $__LOG_JSON__FILE ;;
  esac
}

function __log_json__precmd {
  __LOG_JSON__RC=$?
  if [[ $__LOG_JSON__FINISHED != $__LOG_JSON__ID ]]; then
    __LOG_JSON__FINISHED=$__LOG_JSON__ID
    case $__LOG_JSON__ENGINE in
      jq)      __log_json__end_event_jq      >> $__LOG_JSON__FILE ;;
      python2) __log_json__end_event_python2 >> $__LOG_JSON__FILE ;;
      python3) __log_json__end_event_python3 >> $__LOG_JSON__FILE ;;
      perl)    __log_json__end_event_perl    >> $__LOG_JSON__FILE ;;
    esac
  fi
}

function __log_json__benchmark {
  echo "Python2"
  time {
    for i in $(seq 1000); do
      __log_json__session_event_python2 > /dev/null
    done
  }
  echo

  echo "Python3"
  time {
    for i in $(seq 1000); do
      __log_json__session_event_python3 > /dev/null
    done
  }
  echo

  echo "Perl"
  time {
    for i in $(seq 1000); do
      __log_json__session_event_perl > /dev/null
    done
  }
  echo

  echo "JQ"
  time {
    for i in $(seq 1000); do
      __log_json__session_event_jq > /dev/null
    done
  }
}

__log_json__session_init

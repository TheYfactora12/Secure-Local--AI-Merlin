#!/usr/bin/env bash
# Manage the read-only Merlin status API lifecycle.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

HOST="${MERLIN_STATUS_API_HOST:-127.0.0.1}"
PORT="${MERLIN_STATUS_API_PORT:-8765}"
STATE_DIR="${MERLIN_STATUS_API_STATE_DIR:-${STACK_DIR}/logs}"
PID_FILE="${MERLIN_STATUS_API_PID_FILE:-${STATE_DIR}/merlin-status-api.pid}"
PORT_FILE="${MERLIN_STATUS_API_PORT_FILE:-${STATE_DIR}/merlin-status-api.port}"
LOG_FILE="${MERLIN_STATUS_API_LOG_FILE:-${STATE_DIR}/merlin-status-api.log}"
TRACE_LOG="${MERLIN_TRACE_LOG:-${STACK_DIR}/logs/merlin-route-decisions.jsonl}"
APPROVAL_LOG="${MERLIN_APPROVAL_LOG:-${STACK_DIR}/logs/merlin-approvals.jsonl}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-status-api.sh start [options]
  scripts/merlin-status-api.sh stop [options]
  scripts/merlin-status-api.sh status [options]
  scripts/merlin-status-api.sh run [options]

Options:
  --host <host>              Bind host, default 127.0.0.1
  --port <port>              Bind port, default 8765
  --pid-file <path>          PID file path
  --port-file <path>         Bound port file path
  --log-file <path>          Log file path
  --trace-log <path>         Trace log path passed to API
  --approval-log <path>      Approval log path passed to API

This manager is for the read-only status API only. It does not approve, deny,
execute, start Docker services, call models, write memory, download models, or
use tools.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    start|stop|status|run)
      COMMAND="$1"
      shift
      break
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "expected command: start, stop, status, or run"
      ;;
  esac
done

COMMAND="${COMMAND:-status}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      [[ -n "$HOST" ]] || fail "--host requires a value"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
      [[ "$PORT" =~ ^[0-9]+$ ]] || fail "--port requires a numeric value"
      shift 2
      ;;
    --pid-file)
      PID_FILE="${2:-}"
      [[ -n "$PID_FILE" ]] || fail "--pid-file requires a path"
      shift 2
      ;;
    --port-file)
      PORT_FILE="${2:-}"
      [[ -n "$PORT_FILE" ]] || fail "--port-file requires a path"
      shift 2
      ;;
    --log-file)
      LOG_FILE="${2:-}"
      [[ -n "$LOG_FILE" ]] || fail "--log-file requires a path"
      shift 2
      ;;
    --trace-log)
      TRACE_LOG="${2:-}"
      [[ -n "$TRACE_LOG" ]] || fail "--trace-log requires a path"
      shift 2
      ;;
    --approval-log)
      APPROVAL_LOG="${2:-}"
      [[ -n "$APPROVAL_LOG" ]] || fail "--approval-log requires a path"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

is_pid_running() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" >/dev/null 2>&1
}

pid_from_file() {
  if [[ -f "$PID_FILE" ]]; then
    tr -cd '0-9' < "$PID_FILE"
  fi
}

api_port() {
  if [[ -s "$PORT_FILE" ]]; then
    tr -cd '0-9' < "$PORT_FILE"
  else
    echo "$PORT"
  fi
}

health_url() {
  echo "http://${HOST}:$(api_port)/healthz"
}

status_url() {
  echo "http://${HOST}:$(api_port)/status"
}

health_check() {
  curl -fsS --max-time 2 "$(health_url)" >/dev/null 2>&1
}

start_api() {
  mkdir -p "$(dirname "$PID_FILE")" "$(dirname "$PORT_FILE")" "$(dirname "$LOG_FILE")"

  if health_check; then
    echo "status: running"
    echo "url: $(status_url)"
    echo "execution_allowed: false"
    return 0
  fi

  local existing_pid
  existing_pid="$(pid_from_file)"
  if [[ -n "$existing_pid" ]] && is_pid_running "$existing_pid"; then
    echo "status: unhealthy"
    echo "pid: $existing_pid"
    echo "log_file: $LOG_FILE"
    echo "execution_allowed: false"
    return 1
  fi

  rm -f "$PID_FILE" "$PORT_FILE"
  nohup python3 "${STACK_DIR}/scripts/merlin-status-api.py" \
    --host "$HOST" \
    --port "$PORT" \
    --port-file "$PORT_FILE" \
    --trace-log "$TRACE_LOG" \
    --approval-log "$APPROVAL_LOG" >>"$LOG_FILE" 2>&1 &
  local pid="$!"
  disown "$pid" >/dev/null 2>&1 || true
  echo "$pid" > "$PID_FILE"

  for _ in {1..50}; do
    if health_check; then
      echo "status: started"
      echo "pid: $pid"
      echo "url: $(status_url)"
      echo "log_file: $LOG_FILE"
      echo "execution_allowed: false"
      return 0
    fi
    if ! is_pid_running "$pid"; then
      echo "status: failed"
      echo "pid: $pid"
      echo "log_file: $LOG_FILE"
      echo "execution_allowed: false"
      return 1
    fi
    sleep 0.1
  done

  echo "status: timeout"
  echo "pid: $pid"
  echo "log_file: $LOG_FILE"
  echo "execution_allowed: false"
  return 1
}

stop_api() {
  local pid
  pid="$(pid_from_file)"
  if [[ -n "$pid" ]] && is_pid_running "$pid"; then
    kill "$pid" >/dev/null 2>&1 || true
    for _ in {1..50}; do
      is_pid_running "$pid" || break
      sleep 0.1
    done
    if is_pid_running "$pid"; then
      echo "status: stop_failed"
      echo "pid: $pid"
      echo "execution_allowed: false"
      return 1
    fi
  fi
  rm -f "$PID_FILE"
  echo "status: stopped"
  echo "execution_allowed: false"
}

status_api() {
  local pid
  pid="$(pid_from_file)"
  if health_check; then
    echo "status: running"
    [[ -n "$pid" ]] && echo "pid: $pid"
    echo "url: $(status_url)"
  else
    echo "status: stopped"
    [[ -n "$pid" ]] && echo "pid: $pid"
  fi
  echo "pid_file: $PID_FILE"
  echo "port_file: $PORT_FILE"
  echo "log_file: $LOG_FILE"
  echo "execution_allowed: false"
}

case "$COMMAND" in
  start)
    start_api
    ;;
  stop)
    stop_api
    ;;
  status)
    status_api
    ;;
  run)
    exec python3 "${STACK_DIR}/scripts/merlin-status-api.py" \
      --host "$HOST" \
      --port "$PORT" \
      --port-file "$PORT_FILE" \
      --trace-log "$TRACE_LOG" \
      --approval-log "$APPROVAL_LOG"
    ;;
esac

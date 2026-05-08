#!/usr/bin/env bash
# Manage the Merlin FastAPI task API lifecycle on port 8766.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"

HOST="${MERLIN_TASK_API_HOST:-127.0.0.1}"
PORT="${MERLIN_TASK_API_PORT:-8766}"
STATE_DIR="${MERLIN_TASK_API_STATE_DIR:-${STACK_DIR}/logs}"
PID_FILE="${MERLIN_TASK_API_PID_FILE:-${STATE_DIR}/merlin-task-api.pid}"
PORT_FILE="${MERLIN_TASK_API_PORT_FILE:-${STATE_DIR}/merlin-task-api.port}"
LOG_FILE="${MERLIN_TASK_API_LOG_FILE:-${STATE_DIR}/merlin-task-api.log}"
PYTHON_BIN="${MERLIN_TASK_API_PYTHON:-}"

usage() {
  cat <<'EOF'
Usage:
  scripts/merlin-task-api.sh start [options]
  scripts/merlin-task-api.sh stop [options]
  scripts/merlin-task-api.sh restart [options]
  scripts/merlin-task-api.sh status [options]
  scripts/merlin-task-api.sh run [options]

Options:
  --host <host>              Bind host, default 127.0.0.1
  --port <port>              Bind port, default 8766
  --pid-file <path>          PID file path
  --port-file <path>         Bound port file path
  --log-file <path>          Log file path
  --python <path>            Python interpreter, default .venv/bin/python

This manager is for the Merlin task API only. It does not manage the read-only
status API on port 8765, start Docker services, approve policy gates, pull
models, or merge execution-aware behavior into the status API.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    start|stop|restart|status|run)
      COMMAND="$1"
      shift
      break
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "expected command: start, stop, restart, status, or run"
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
    --python)
      PYTHON_BIN="${2:-}"
      [[ -n "$PYTHON_BIN" ]] || fail "--python requires a path"
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

resolve_python() {
  if [[ -n "$PYTHON_BIN" ]]; then
    echo "$PYTHON_BIN"
    return
  fi
  if [[ -x "${STACK_DIR}/.venv/bin/python" ]]; then
    echo "${STACK_DIR}/.venv/bin/python"
    return
  fi
  if [[ -x "${STACK_DIR}/.venv-test/bin/python" ]]; then
    echo "${STACK_DIR}/.venv-test/bin/python"
    return
  fi
  echo "python3"
}

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

routes_url() {
  echo "http://${HOST}:$(api_port)/status/routes"
}

health_check() {
  curl -fsS --max-time 2 "$(routes_url)" >/dev/null 2>&1
}

port_listener_pids() {
  command -v lsof >/dev/null 2>&1 || return 0
  lsof -tiTCP:"$(api_port)" -sTCP:LISTEN 2>/dev/null | sort -u
}

stop_port_listeners() {
  local pid
  local pids
  pids="$(port_listener_pids || true)"
  [[ -n "$pids" ]] || return 0

  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    kill "$pid" >/dev/null 2>&1 || true
  done <<< "$pids"

  for _ in {1..50}; do
    health_check || return 0
    sleep 0.1
  done
  return 1
}

write_port_file() {
  mkdir -p "$(dirname "$PORT_FILE")"
  echo "$PORT" > "$PORT_FILE"
}

run_api() {
  local python_bin
  python_bin="$(resolve_python)"
  cd "$STACK_DIR"
  write_port_file
  PYTHONPATH="$STACK_DIR" exec "$python_bin" -m uvicorn merlin.task_endpoint:app --host "$HOST" --port "$PORT"
}

start_api() {
  mkdir -p "$(dirname "$PID_FILE")" "$(dirname "$PORT_FILE")" "$(dirname "$LOG_FILE")"

  if health_check; then
    echo "status: running"
    echo "url: $(routes_url)"
    return 0
  fi

  local existing_pid
  existing_pid="$(pid_from_file)"
  if [[ -n "$existing_pid" ]] && is_pid_running "$existing_pid"; then
    echo "status: unhealthy"
    echo "pid: $existing_pid"
    echo "log_file: $LOG_FILE"
    return 1
  fi

  rm -f "$PID_FILE" "$PORT_FILE"
  nohup "$SCRIPT_PATH" run \
    --host "$HOST" \
    --port "$PORT" \
    --port-file "$PORT_FILE" \
    --log-file "$LOG_FILE" \
    --python "$(resolve_python)" >>"$LOG_FILE" 2>&1 &
  local pid="$!"
  disown "$pid" >/dev/null 2>&1 || true
  echo "$pid" > "$PID_FILE"

  for _ in {1..100}; do
    if health_check; then
      echo "status: started"
      echo "pid: $pid"
      echo "url: $(routes_url)"
      echo "log_file: $LOG_FILE"
      return 0
    fi
    if ! is_pid_running "$pid"; then
      echo "status: failed"
      echo "pid: $pid"
      echo "log_file: $LOG_FILE"
      return 1
    fi
    sleep 0.1
  done

  echo "status: timeout"
  echo "pid: $pid"
  echo "log_file: $LOG_FILE"
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
      return 1
    fi
  fi
  rm -f "$PID_FILE"
  echo "status: stopped"
}

status_api() {
  local pid
  pid="$(pid_from_file)"
  if health_check; then
    echo "status: running"
    [[ -n "$pid" ]] && is_pid_running "$pid" && echo "pid: $pid"
    echo "url: $(routes_url)"
  else
    echo "status: stopped"
    [[ -n "$pid" ]] && is_pid_running "$pid" && echo "pid: $pid"
  fi
  echo "pid_file: $PID_FILE"
  echo "port_file: $PORT_FILE"
  echo "log_file: $LOG_FILE"
}

restart_api() {
  stop_api >/dev/null
  if health_check; then
    if ! stop_port_listeners; then
      echo "status: restart_failed"
      echo "reason: existing listener on $(routes_url) could not be stopped"
      echo "log_file: $LOG_FILE"
      return 1
    fi
  fi
  start_api
}

case "$COMMAND" in
  start)
    start_api
    ;;
  stop)
    stop_api
    ;;
  restart)
    restart_api
    ;;
  status)
    status_api
    ;;
  run)
    run_api
    ;;
esac

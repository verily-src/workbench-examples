#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=8080
LOG_FILE="${SCRIPT_DIR}/server.log"
PID_FILE="${SCRIPT_DIR}/server.pid"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [start|stop|restart|status|logs]

Commands:
  start    Install deps, kill stale server, launch, smoke-test, print URL
  stop     Stop the running dashboard server
  restart  stop + start
  status   Show whether the server is running and print the URL
  logs     Tail the server log

If no command is given, "start" is assumed.
EOF
}

ensure_deps() {
    local missing=()
    for pkg in flask flask-cors pandas google-cloud-bigquery db-dtypes; do
        if ! python3 -c "import importlib; importlib.import_module('${pkg//-/_}')" 2>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        info "Installing missing packages: ${missing[*]}"
        pip install --quiet "${missing[@]}"
    fi
}

get_app_uuid() {
    wb app list --format=json 2>/dev/null \
        | jq -r '.[] | select(.status == "RUNNING") | .proxyUrl' \
        | head -1 \
        | grep -oP '[a-f0-9-]{36}' \
        || true
}

kill_port() {
    local pids
    pids=$(lsof -t -i :"$PORT" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        warn "Killing existing process(es) on port ${PORT}: ${pids}"
        echo "$pids" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    rm -f "$PID_FILE"
}

do_start() {
    info "Ensuring Python dependencies..."
    ensure_deps

    kill_port

    info "Starting dashboard on port ${PORT}..."
    cd "$SCRIPT_DIR"
    nohup python3 app.py > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    # Wait for the server to respond
    local retries=0
    while ! curl -sf "http://localhost:${PORT}/" >/dev/null 2>&1; do
        retries=$((retries + 1))
        if [[ $retries -ge 15 ]]; then
            error "Server failed to start within 15 seconds."
            error "Last 20 lines of ${LOG_FILE}:"
            tail -20 "$LOG_FILE"
            exit 1
        fi
        sleep 1
    done

    info "Server is up (PID ${pid})."

    # Smoke-test the API endpoints
    local ok=true
    for endpoint in api/cohort-overview api/mutation-landscape api/drug-target-map api/treatment-outcomes; do
        local status
        status=$(curl -so /dev/null -w "%{http_code}" "http://localhost:${PORT}/${endpoint}" 2>/dev/null || echo "000")
        if [[ "$status" == "200" ]]; then
            info "  /${endpoint} — ${GREEN}200 OK${NC}"
        else
            error "  /${endpoint} — ${RED}${status}${NC}"
            ok=false
        fi
    done

    if [[ "$ok" == false ]]; then
        warn "Some endpoints failed. Check ${LOG_FILE} for details."
    fi

    # Print the Workbench proxy URL
    local uuid
    uuid=$(get_app_uuid)
    echo ""
    if [[ -n "$uuid" ]]; then
        info "Dashboard URL:"
        echo -e "  ${GREEN}https://workbench.verily.com/app/${uuid}/proxy/${PORT}/${NC}"
    else
        warn "Could not determine app UUID — is 'wb' CLI configured?"
        info "Local URL: http://localhost:${PORT}/"
    fi
}

do_stop() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            info "Stopping server (PID ${pid})..."
            kill "$pid" 2>/dev/null || true
            rm -f "$PID_FILE"
            info "Stopped."
            return
        fi
        rm -f "$PID_FILE"
    fi
    # Fallback: kill anything on the port
    local pids
    pids=$(lsof -t -i :"$PORT" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        info "Stopping process(es) on port ${PORT}..."
        echo "$pids" | xargs kill 2>/dev/null || true
        info "Stopped."
    else
        info "No dashboard server running on port ${PORT}."
    fi
}

do_status() {
    local pids
    pids=$(lsof -t -i :"$PORT" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        info "Dashboard is running (PID ${pids}) on port ${PORT}."
        local uuid
        uuid=$(get_app_uuid)
        if [[ -n "$uuid" ]]; then
            info "URL: https://workbench.verily.com/app/${uuid}/proxy/${PORT}/"
        fi
    else
        info "Dashboard is not running."
    fi
}

do_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        tail -f "$LOG_FILE"
    else
        error "No log file found at ${LOG_FILE}"
        exit 1
    fi
}

CMD="${1:-start}"
case "$CMD" in
    start)   do_start   ;;
    stop)    do_stop    ;;
    restart) do_stop; do_start ;;
    status)  do_status  ;;
    logs)    do_logs    ;;
    -h|--help) usage    ;;
    *)
        error "Unknown command: $CMD"
        usage
        exit 1
        ;;
esac

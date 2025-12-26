#!/usr/bin/env bash
# MCP Server launcher - ensures correct Python path and validates environment

set -e

# Change to project root
cd "$(dirname "$0")/.."
PROJECT_ROOT="$(pwd)"

# Set up Python path
export PYTHONPATH="${PYTHONPATH}:${PROJECT_ROOT}"

# FastAPI URL (default to localhost:8000)
FASTAPI_URL="${FASTAPI_URL:-http://localhost:8000}"

# Log to stderr for debugging (MCP uses stdout for JSON-RPC)
log() {
    echo "[MCP-SERVER] $1" >&2
}

# Check if FastAPI is running (non-blocking, just a warning)
check_fastapi() {
    if curl -s --connect-timeout 2 "${FASTAPI_URL}/health" > /dev/null 2>&1; then
        log "FastAPI backend is healthy at ${FASTAPI_URL}"
    else
        log "WARNING: FastAPI backend may not be running at ${FASTAPI_URL}"
        log "Tool calls will fail until backend is available"
    fi
}

# Verify Python and virtual environment
if [ ! -f "${PROJECT_ROOT}/venv/bin/python" ]; then
    log "ERROR: Virtual environment not found at ${PROJECT_ROOT}/venv"
    log "Run: python3 -m venv venv && pip install -r requirements.txt"
    exit 1
fi

# Check FastAPI (in background to not delay startup)
check_fastapi &

# Run the MCP server
log "Starting MCP server from ${PROJECT_ROOT}"
exec "${PROJECT_ROOT}/venv/bin/python" -m mcp_server.server "$@"

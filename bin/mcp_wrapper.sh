#!/usr/bin/env bash
# ==============================================================================
# MCP Server Wrapper - Ensures all dependencies are running
# ==============================================================================
# This script is called by Antigravity's MCP client. It:
# 1. Starts MySQL (Docker) if not running
# 2. Starts FastAPI if not running
# 3. Starts the MCP server
#
# All output goes to logs for debugging.
# ==============================================================================

# Get project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"

# Log file for this wrapper
WRAPPER_LOG="$PROJECT_ROOT/logs/mcp_wrapper.log"

# Function to log (to file only, stderr is for MCP)
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$WRAPPER_LOG"
}

log "========================================"
log "MCP Wrapper starting..."
log "Project root: $PROJECT_ROOT"

# ==============================================================================
# 1. Check/Start MySQL
# ==============================================================================
start_mysql_if_needed() {
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "data_recon_mysql"; then
        log "MySQL is already running"
    else
        log "Starting MySQL..."
        docker compose -f "$PROJECT_ROOT/tests/docker-compose.yml" up -d >> "$WRAPPER_LOG" 2>&1
        
        # Wait for MySQL to be ready (max 30 seconds)
        for i in {1..30}; do
            if docker exec data_recon_mysql mysqladmin ping -h localhost -u root -prootpassword > /dev/null 2>&1; then
                log "MySQL is ready after ${i}s"
                return 0
            fi
            sleep 1
        done
        log "WARNING: MySQL may not be ready"
    fi
}

# ==============================================================================
# 2. Check/Start FastAPI
# ==============================================================================
start_fastapi_if_needed() {
    local FASTAPI_URL="${FASTAPI_URL:-http://localhost:8000}"
    
    if curl -s --connect-timeout 2 "$FASTAPI_URL/health" > /dev/null 2>&1; then
        log "FastAPI is already running at $FASTAPI_URL"
    else
        log "Starting FastAPI..."
        
        # Activate virtual environment and start FastAPI in background
        source "$PROJECT_ROOT/venv/bin/activate"
        nohup uvicorn data_recon.main:app --host 0.0.0.0 --port 8000 >> "$PROJECT_ROOT/logs/fastapi.log" 2>&1 &
        echo $! > "$PROJECT_ROOT/logs/fastapi.pid"
        
        # Wait for FastAPI to be ready (max 15 seconds)
        for i in {1..15}; do
            if curl -s --connect-timeout 1 "$FASTAPI_URL/health" > /dev/null 2>&1; then
                log "FastAPI is ready after ${i}s"
                return 0
            fi
            sleep 1
        done
        log "WARNING: FastAPI may not be ready"
    fi
}

# ==============================================================================
# 3. Start services and then MCP server
# ==============================================================================

# Start dependencies
start_mysql_if_needed
start_fastapi_if_needed

# Verify FastAPI is actually ready
FASTAPI_URL="${FASTAPI_URL:-http://localhost:8000}"
if curl -s --connect-timeout 2 "$FASTAPI_URL/health" > /dev/null 2>&1; then
    log "FastAPI health check: OK"
else
    log "ERROR: FastAPI is not responding!"
fi

# ==============================================================================
# 4. Now start the MCP server
# ==============================================================================
log "Starting MCP server..."

# Set up Python path and run MCP server
export PYTHONPATH="${PYTHONPATH}:${PROJECT_ROOT}"
export FASTAPI_URL="${FASTAPI_URL:-http://localhost:8000}"

# Execute the Python MCP server (this replaces the current process)
exec "$PROJECT_ROOT/venv/bin/python" "$PROJECT_ROOT/bin/mcp_server_main.py"

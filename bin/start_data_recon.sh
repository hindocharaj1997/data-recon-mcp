#!/usr/bin/env bash
# ==============================================================================
# Data Recon Stack Startup Script
# ==============================================================================
# This script ensures all required services are running before using the
# Data Recon MCP server with Antigravity.
#
# Usage:
#   ./start_data_recon.sh        # Start all services
#   ./start_data_recon.sh status # Check status only
#   ./start_data_recon.sh stop   # Stop all services
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if a service is running
check_mysql() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "data_recon_mysql"
}

check_fastapi() {
    curl -s --connect-timeout 2 http://localhost:8000/health > /dev/null 2>&1
}

# Start MySQL
start_mysql() {
    if check_mysql; then
        log_info "MySQL is already running"
    else
        log_info "Starting MySQL..."
        docker compose -f tests/docker-compose.yml up -d
        
        # Wait for MySQL to be healthy
        log_info "Waiting for MySQL to be ready..."
        for i in {1..30}; do
            if docker exec data_recon_mysql mysqladmin ping -h localhost -u root -prootpassword > /dev/null 2>&1; then
                log_info "MySQL is ready!"
                return 0
            fi
            sleep 1
        done
        log_error "MySQL failed to start"
        return 1
    fi
}

# Start FastAPI
start_fastapi() {
    if check_fastapi; then
        log_info "FastAPI is already running"
    else
        log_info "Starting FastAPI..."
        source venv/bin/activate
        nohup uvicorn data_recon.main:app --host 0.0.0.0 --port 8000 > logs/fastapi.log 2>&1 &
        echo $! > logs/fastapi.pid
        
        # Wait for FastAPI to be ready
        log_info "Waiting for FastAPI to be ready..."
        for i in {1..10}; do
            if check_fastapi; then
                log_info "FastAPI is ready!"
                return 0
            fi
            sleep 1
        done
        log_error "FastAPI failed to start. Check logs/fastapi.log"
        return 1
    fi
}

# Stop all services
stop_all() {
    log_info "Stopping services..."
    
    # Stop FastAPI
    if [ -f logs/fastapi.pid ]; then
        kill $(cat logs/fastapi.pid) 2>/dev/null || true
        rm logs/fastapi.pid
        log_info "FastAPI stopped"
    fi
    
    # Stop MySQL
    docker compose -f tests/docker-compose.yml down 2>/dev/null || true
    log_info "MySQL stopped"
}

# Show status
show_status() {
    echo ""
    echo "=== Data Recon Stack Status ==="
    echo ""
    
    if check_mysql; then
        log_info "MySQL: ✅ Running"
    else
        log_error "MySQL: ❌ Not running"
    fi
    
    if check_fastapi; then
        log_info "FastAPI: ✅ Running (http://localhost:8000)"
    else
        log_error "FastAPI: ❌ Not running"
    fi
    
    echo ""
    echo "To use with Antigravity, make sure both services are running!"
    echo ""
}

# Main
case "${1:-start}" in
    start)
        echo ""
        echo "=== Starting Data Recon Stack ==="
        echo ""
        start_mysql
        start_fastapi
        echo ""
        show_status
        echo "You can now use the data-recon MCP tools in Antigravity!"
        ;;
    stop)
        stop_all
        ;;
    status)
        show_status
        ;;
    restart)
        stop_all
        sleep 2
        start_mysql
        start_fastapi
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac

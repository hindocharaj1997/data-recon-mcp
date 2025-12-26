#!/bin/bash
# Stop Data Reconciliation services

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🛑 Stopping Data Reconciliation Services..."
echo ""

# Stop FastAPI server
if [ -f "$PROJECT_DIR/logs/fastapi.pid" ]; then
    FASTAPI_PID=$(cat "$PROJECT_DIR/logs/fastapi.pid")
    if ps -p $FASTAPI_PID > /dev/null 2>&1; then
        echo "   Stopping FastAPI (PID: $FASTAPI_PID)..."
        kill $FASTAPI_PID 2>/dev/null
        rm "$PROJECT_DIR/logs/fastapi.pid"
        echo "✅ FastAPI stopped"
    else
        echo "   FastAPI not running (stale PID file)"
        rm "$PROJECT_DIR/logs/fastapi.pid"
    fi
else
    # Try to find and kill by port
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "   Stopping process on port 8000..."
        kill $(lsof -t -i:8000) 2>/dev/null
        echo "✅ FastAPI stopped"
    else
        echo "   FastAPI not running"
    fi
fi

# Stop MySQL container
echo ""
echo "📦 Stopping MySQL container..."
cd "$SCRIPT_DIR"
docker-compose down

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ All services stopped!"
echo ""
echo "💡 Data is preserved in Docker volume."
echo "   To remove data too: docker-compose down -v"
echo "═══════════════════════════════════════════════════"

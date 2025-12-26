#!/bin/bash
# Start Data Reconciliation services

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting Data Reconciliation Services..."
echo ""

# Start MySQL container
echo "📦 Starting MySQL container..."
cd "$SCRIPT_DIR"
docker-compose up -d

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
until docker exec data_recon_mysql mysqladmin ping -h localhost -u root -prootpassword --silent 2>/dev/null; do
    printf "."
    sleep 2
done
echo ""
echo "✅ MySQL is ready!"

# Start FastAPI server
echo ""
echo "🌐 Starting FastAPI server..."
cd "$PROJECT_DIR"

# Kill any existing process on port 8000
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "   Stopping existing process on port 8000..."
    kill $(lsof -t -i:8000) 2>/dev/null || true
    sleep 2
fi

# Activate venv and start uvicorn in background
source venv/bin/activate
nohup uvicorn data_recon.main:app --host 0.0.0.0 --port 8000 > logs/fastapi.log 2>&1 &
FASTAPI_PID=$!

# Save PID for stop script
mkdir -p "$PROJECT_DIR/logs"
echo $FASTAPI_PID > "$PROJECT_DIR/logs/fastapi.pid"

# Wait for FastAPI to start
sleep 3

if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ FastAPI server started (PID: $FASTAPI_PID)"
else
    echo "⚠️  FastAPI may still be starting. Check logs/fastapi.log"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ All services started!"
echo ""
echo "🔗 FastAPI:  http://localhost:8000"
echo "📖 Swagger:  http://localhost:8000/docs"
echo "🗄️  MySQL:    localhost:3306"
echo ""
echo "📊 Test databases:"
echo "   • source_db (10 orders)"
echo "   • target_db (9 orders)"
echo ""
echo "🛑 To stop: ./tests/stop_services.sh"
echo "═══════════════════════════════════════════════════"

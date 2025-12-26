#!/bin/bash
# Test environment setup script

set -e

echo "🚀 Setting up Data Reconciliation test environment..."
echo ""

# Navigate to tests directory
cd "$(dirname "$0")"

# Start MySQL container
echo "📦 Starting MySQL container..."
docker-compose up -d

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
until docker exec data_recon_mysql mysqladmin ping -h localhost -u root -prootpassword --silent 2>/dev/null; do
    printf "."
    sleep 2
done
echo ""
echo "✅ MySQL is ready!"

# Show database info
echo ""
echo "📊 Test databases created:"
echo "  - source_db (10 orders, 5 customers, 5 products)"
echo "  - target_db (9 orders - missing 1, same customers, products with schema diff)"
echo ""
echo "📋 Test data differences for reconciliation testing:"
echo "  1. Row count: source_db.orders=10, target_db.orders=9"
echo "  2. Schema diff: products.price has different precision"
echo "  3. Schema diff: target_db.products has extra 'is_active' column"
echo "  4. Aggregate diff: SUM(total_amount) differs by $1299.97"
echo ""

# Connection details
echo "🔌 MySQL Connection Details:"
echo "  Host: localhost"
echo "  Port: 3306"
echo "  Username: recon_user"
echo "  Password: recon_password"
echo "  Databases: source_db, target_db"
echo ""

# Navigate back to project root and set up Python environment
cd ..
echo "🐍 Setting up Python environment..."

# Create venv if doesn't exist
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install -r requirements.txt -q

echo "✅ Python environment ready!"
echo ""

# Start FastAPI server in background
echo "🌐 Starting FastAPI server on port 8000..."
echo ""

# Check if port 8000 is already in use
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port 8000 is already in use. Killing existing process..."
    kill $(lsof -t -i:8000) 2>/dev/null || true
    sleep 2
fi

# Start FastAPI
uvicorn data_recon.main:app --host 0.0.0.0 --port 8000 &
FASTAPI_PID=$!

echo "FastAPI server started (PID: $FASTAPI_PID)"
echo ""

# Wait for FastAPI to be ready
sleep 3

echo "🎉 Test environment is ready!"
echo ""
echo "📝 Next steps:"
echo "  1. API docs: http://localhost:8000/docs"
echo "  2. Add data sources using curl or the API"
echo "  3. Configure MCP server in Antigravity"
echo ""
echo "📋 Quick test commands:"
echo ""
echo "  # Add source MySQL:"
echo '  curl -X POST http://localhost:8000/datasources -H "Content-Type: application/json" -d '"'"'{"name":"mysql_source","type":"mysql","connection_config":{"host":"localhost","port":3306,"username":"recon_user","password":"recon_password","database":"source_db"}}'"'"
echo ""
echo "  # Add target MySQL:"
echo '  curl -X POST http://localhost:8000/datasources -H "Content-Type: application/json" -d '"'"'{"name":"mysql_target","type":"mysql","connection_config":{"host":"localhost","port":3306,"username":"recon_user","password":"recon_password","database":"target_db"}}'"'"
echo ""
echo "To stop: docker-compose -f tests/docker-compose.yml down && kill $FASTAPI_PID"

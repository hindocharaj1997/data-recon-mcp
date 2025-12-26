#!/bin/bash
# Check status of Data Reconciliation services

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📊 Data Reconciliation Services Status"
echo "═══════════════════════════════════════════════════"

# Check MySQL
echo ""
echo "🗄️  MySQL Container:"
if docker ps --format '{{.Names}}' | grep -q 'data_recon_mysql'; then
    VERSION=$(docker exec data_recon_mysql mysql -u root -prootpassword -e "SELECT VERSION();" 2>/dev/null | tail -1)
    echo "   ✅ Running (MySQL $VERSION)"
    echo "   📊 Databases: source_db, target_db"
else
    echo "   ❌ Not running"
fi

# Check FastAPI
echo ""
echo "🌐 FastAPI Server:"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   ✅ Running on http://localhost:8000"
    echo "   📖 Swagger: http://localhost:8000/docs"
else
    echo "   ❌ Not running"
fi

# Check data sources
echo ""
echo "📁 Registered Data Sources:"
if curl -s http://localhost:8000/datasources 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data:
        for ds in data:
            print(f\"   • {ds['name']} ({ds['type']})\")
    else:
        print('   (none)')
except:
    print('   (unavailable)')
" 2>/dev/null; then
    :
else
    echo "   (FastAPI not running)"
fi

echo ""
echo "═══════════════════════════════════════════════════"

#!/bin/bash
set -e

echo "🚀 Setting up Data Reconciliation MCP Server..."

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Start the FastAPI server:"
echo "   source venv/bin/activate"
echo "   uvicorn data_recon.main:app --port 8000"
echo ""
echo "2. Add this to your Antigravity MCP config:"
echo ""
cat << EOF
{
  "mcpServers": {
    "data-recon": {
      "command": "$(pwd)/venv/bin/python",
      "args": ["$(pwd)/mcp_server/server.py"],
      "env": {
        "FASTAPI_URL": "http://localhost:8000"
      }
    }
  }
}
EOF
echo ""
echo "3. (Optional) Pre-configure data sources in env:"
echo '   "DATASOURCE_MYSQL_PROD": "{\"type\":\"mysql\",\"host\":\"...\",\"port\":3306,\"username\":\"...\",\"password\":\"...\",\"database\":\"...\"}"'
echo ""

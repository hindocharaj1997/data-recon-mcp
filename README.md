# Data Reconciliation MCP Server

A framework for data reconciliation between MySQL and Snowflake databases, exposed via MCP tools for Antigravity.

## Quick Start

```bash
# 1. Setup
./setup.sh

# 2. Start FastAPI server
source venv/bin/activate
uvicorn data_recon.main:app --port 8000

# 3. Configure Antigravity (see setup.sh output for config snippet)
```

## Features

- **23 MCP Tools** for comprehensive data reconciliation
- MySQL and Snowflake support
- Async job execution with progress tracking
- Pre-configured data sources via environment variables

## MCP Tools

| Category | Tools |
|----------|-------|
| Data Source Management | 7 |
| Discovery & Validation | 7 |
| Individual Checks | 4 |
| Job Management | 5 |

## Future Enhancements

- Scheduled/recurring jobs
- Secret manager integration
- Additional database connectors

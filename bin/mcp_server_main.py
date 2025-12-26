#!/usr/bin/env python3
"""
Robust MCP Server entry point with comprehensive error handling and logging.

This is the most defensive implementation possible for debugging.
"""

import os
import sys
import traceback
import json
from datetime import datetime

# CRITICAL: Set up paths BEFORE any other imports
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

# Log file for debugging
LOG_FILE = os.path.join(PROJECT_ROOT, "logs", "mcp_server.log")
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)


def log(msg: str, to_file: bool = True):
    """Log to both stderr and file."""
    timestamp = datetime.now().isoformat()
    formatted = f"[{timestamp}] [MCP] {msg}"
    print(formatted, file=sys.stderr, flush=True)
    if to_file:
        try:
            with open(LOG_FILE, "a") as f:
                f.write(formatted + "\n")
        except:
            pass


def main():
    """Main entry point with defensive error handling."""
    log("=" * 60)
    log("MCP Server starting...")
    log(f"Python: {sys.executable}")
    log(f"Version: {sys.version}")
    log(f"Project root: {PROJECT_ROOT}")
    log(f"CWD: {os.getcwd()}")
    log(f"PYTHONPATH: {os.environ.get('PYTHONPATH', 'not set')}")
    log(f"FASTAPI_URL: {os.environ.get('FASTAPI_URL', 'not set')}")
    
    # Set default FastAPI URL
    fastapi_url = os.environ.get("FASTAPI_URL", "http://localhost:8000")
    os.environ["FASTAPI_URL"] = fastapi_url
    log(f"Using FastAPI URL: {fastapi_url}")
    
    # Test FastAPI connection
    try:
        import httpx
        log("Testing FastAPI connection...")
        with httpx.Client(timeout=5.0) as client:
            response = client.get(f"{fastapi_url}/health")
            if response.status_code == 200:
                log(f"FastAPI is healthy: {response.text}")
            else:
                log(f"WARNING: FastAPI returned status {response.status_code}")
    except Exception as e:
        log(f"WARNING: FastAPI connection failed: {e}")
        log("Tool calls will fail until backend is available")
    
    # Import MCP components
    try:
        log("Importing MCP components...")
        import asyncio
        from mcp.server import Server
        from mcp.server.stdio import stdio_server
        from mcp.types import Tool, TextContent
        from mcp_server.server import create_server, register_preconfigured_datasources
        log("Imports successful")
    except Exception as e:
        log(f"FATAL: Import failed: {e}")
        log(traceback.format_exc())
        sys.exit(1)
    
    # Run the server
    async def run_server():
        log("Registering pre-configured data sources...")
        await register_preconfigured_datasources()
        
        log("Creating MCP server...")
        server = create_server()
        
        log("Starting stdio server...")
        async with stdio_server() as (read_stream, write_stream):
            log("MCP Server ready - waiting for client messages")
            await server.run(
                read_stream,
                write_stream,
                server.create_initialization_options()
            )
    
    try:
        log("Starting async event loop...")
        asyncio.run(run_server())
    except KeyboardInterrupt:
        log("Server stopped by user (KeyboardInterrupt)")
    except Exception as e:
        log(f"FATAL: Server error: {e}")
        log(traceback.format_exc())
        sys.exit(1)
    
    log("Server shutdown complete")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        # Last resort error handler
        try:
            log(f"FATAL UNHANDLED: {e}")
            log(traceback.format_exc())
        except:
            print(f"FATAL: {e}", file=sys.stderr)
        sys.exit(1)

# Test Environment

This folder contains test infrastructure for the Data Reconciliation MCP Server.

## Quick Start

```bash
./setup_test_env.sh
```

This will:
1. Start MySQL in Docker with test databases
2. Create source_db and target_db with sample data
3. Start the FastAPI server
4. Print connection details and test commands

## Test Data

### Source Database (source_db)
- 10 orders
- 5 customers
- 5 products
- 15 order_items

### Target Database (target_db)
- 9 orders (missing order #10)
- 5 customers (same)
- 5 products (schema differences)
- 13 order_items

### Intentional Differences for Testing
1. **Row count mismatch**: orders table (10 vs 9)
2. **Schema difference**: products.price has different precision
3. **Missing column**: products.is_active only in target
4. **Aggregate difference**: SUM(total_amount) differs by $1,299.97

## MySQL Connection

```
Host: localhost
Port: 3306
Username: recon_user
Password: recon_password
```

## Cleanup

```bash
docker-compose down -v  # Removes containers and data
```

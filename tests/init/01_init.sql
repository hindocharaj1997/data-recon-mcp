-- Initialize test databases and tables for data reconciliation testing
-- This script runs automatically when MySQL container starts

-- =====================================================
-- SOURCE DATABASE - Simulates production source
-- =====================================================
CREATE DATABASE IF NOT EXISTS source_db;
USE source_db;

-- Grant privileges
GRANT ALL PRIVILEGES ON source_db.* TO 'recon_user'@'%';

-- Orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Order items table
CREATE TABLE order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT DEFAULT 0
);

-- Insert sample data
INSERT INTO customers (first_name, last_name, email) VALUES
('John', 'Doe', 'john.doe@example.com'),
('Jane', 'Smith', 'jane.smith@example.com'),
('Bob', 'Johnson', 'bob.johnson@example.com'),
('Alice', 'Williams', 'alice.williams@example.com'),
('Charlie', 'Brown', 'charlie.brown@example.com');

INSERT INTO products (name, category, price, stock_quantity) VALUES
('Laptop', 'Electronics', 999.99, 50),
('Mouse', 'Electronics', 29.99, 200),
('Keyboard', 'Electronics', 79.99, 150),
('Monitor', 'Electronics', 299.99, 75),
('Headphones', 'Electronics', 149.99, 100);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-15 10:30:00', 1029.98, 'completed'),
(2, '2024-01-16 14:45:00', 329.98, 'completed'),
(1, '2024-01-17 09:15:00', 149.99, 'completed'),
(3, '2024-01-18 16:20:00', 1079.97, 'pending'),
(4, '2024-01-19 11:00:00', 109.98, 'completed'),
(5, '2024-01-20 13:30:00', 999.99, 'shipped'),
(2, '2024-01-21 15:45:00', 229.98, 'completed'),
(3, '2024-01-22 08:30:00', 449.97, 'completed'),
(1, '2024-01-23 17:00:00', 79.99, 'processing'),
(4, '2024-01-24 12:15:00', 1299.97, 'completed');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 999.99), (1, 2, 1, 29.99),
(2, 4, 1, 299.99), (2, 2, 1, 29.99),
(3, 5, 1, 149.99),
(4, 1, 1, 999.99), (4, 3, 1, 79.99),
(5, 2, 2, 29.99), (5, 3, 1, 79.99),
(6, 1, 1, 999.99),
(7, 5, 1, 149.99), (7, 3, 1, 79.99),
(8, 5, 3, 149.99),
(9, 3, 1, 79.99),
(10, 1, 1, 999.99), (10, 4, 1, 299.99);


-- =====================================================
-- TARGET DATABASE - Simulates migration target
-- =====================================================
CREATE DATABASE IF NOT EXISTS target_db;
USE target_db;

-- Grant privileges
GRANT ALL PRIVILEGES ON target_db.* TO 'recon_user'@'%';

-- Orders table (same structure as source)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Order items table
CREATE TABLE order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table (slightly different to test schema comparison)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(12, 4) NOT NULL,  -- Different precision!
    stock_quantity INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE  -- Extra column!
);

-- Copy MOST data from source (simulate migration with some differences)
INSERT INTO customers (first_name, last_name, email) VALUES
('John', 'Doe', 'john.doe@example.com'),
('Jane', 'Smith', 'jane.smith@example.com'),
('Bob', 'Johnson', 'bob.johnson@example.com'),
('Alice', 'Williams', 'alice.williams@example.com'),
('Charlie', 'Brown', 'charlie.brown@example.com');

INSERT INTO products (name, category, price, stock_quantity, is_active) VALUES
('Laptop', 'Electronics', 999.99, 50, TRUE),
('Mouse', 'Electronics', 29.99, 200, TRUE),
('Keyboard', 'Electronics', 79.99, 150, TRUE),
('Monitor', 'Electronics', 299.99, 75, TRUE),
('Headphones', 'Electronics', 149.99, 100, TRUE);

-- Insert orders with ONE DIFFERENCE (missing order_id 10)
INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-15 10:30:00', 1029.98, 'completed'),
(2, '2024-01-16 14:45:00', 329.98, 'completed'),
(1, '2024-01-17 09:15:00', 149.99, 'completed'),
(3, '2024-01-18 16:20:00', 1079.97, 'pending'),
(4, '2024-01-19 11:00:00', 109.98, 'completed'),
(5, '2024-01-20 13:30:00', 999.99, 'shipped'),
(2, '2024-01-21 15:45:00', 229.98, 'completed'),
(3, '2024-01-22 08:30:00', 449.97, 'completed'),
(1, '2024-01-23 17:00:00', 79.99, 'processing');
-- Missing order 10!

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 999.99), (1, 2, 1, 29.99),
(2, 4, 1, 299.99), (2, 2, 1, 29.99),
(3, 5, 1, 149.99),
(4, 1, 1, 999.99), (4, 3, 1, 79.99),
(5, 2, 2, 29.99), (5, 3, 1, 79.99),
(6, 1, 1, 999.99),
(7, 5, 1, 149.99), (7, 3, 1, 79.99),
(8, 5, 3, 149.99),
(9, 3, 1, 79.99);
-- Missing order_items for order 10!

FLUSH PRIVILEGES;

-- Summary of test data differences:
-- 1. source_db.orders has 10 rows, target_db.orders has 9 rows (missing order_id 10)
-- 2. source_db.products.price is DECIMAL(10,2), target_db.products.price is DECIMAL(12,4)
-- 3. target_db.products has extra column 'is_active'
-- 4. SUM(total_amount) will differ by 1299.97 (the missing order)

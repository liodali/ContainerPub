-- ContainerPub Database Initialization Script
-- This script creates the necessary databases and tables

-- Create functions database if it doesn't exist
SELECT 'CREATE DATABASE functions_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'functions_db')\gexec

-- Connect to main database
\c dart_cloud

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create functions table
CREATE TABLE IF NOT EXISTS functions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    code TEXT NOT NULL,
    runtime VARCHAR(50) DEFAULT 'dart',
    status VARCHAR(50) DEFAULT 'active',
    endpoint VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, name)
);

-- Create function_logs table
CREATE TABLE IF NOT EXISTS function_logs (
    id SERIAL PRIMARY KEY,
    function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    execution_time_ms INTEGER,
    status VARCHAR(50),
    error_message TEXT,
    request_data JSONB,
    response_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_functions_user_id ON functions(user_id);
CREATE INDEX IF NOT EXISTS idx_functions_endpoint ON functions(endpoint);
CREATE INDEX IF NOT EXISTS idx_function_logs_function_id ON function_logs(function_id);
CREATE INDEX IF NOT EXISTS idx_function_logs_created_at ON function_logs(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_functions_updated_at ON functions;
CREATE TRIGGER update_functions_updated_at
    BEFORE UPDATE ON functions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Connect to functions database
\c functions_db

-- Create function_data table for user functions to store data
CREATE TABLE IF NOT EXISTS function_data (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) NOT NULL,
    value JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(key)
);

-- Create index for function_data
CREATE INDEX IF NOT EXISTS idx_function_data_key ON function_data(key);

-- Create updated_at trigger for function_data
DROP TRIGGER IF EXISTS update_function_data_updated_at ON function_data;
CREATE TRIGGER update_function_data_updated_at
    BEFORE UPDATE ON function_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (optional, adjust as needed)
-- GRANT ALL PRIVILEGES ON DATABASE dart_cloud TO dart_cloud;
-- GRANT ALL PRIVILEGES ON DATABASE functions_db TO dart_cloud;

-- Print success message
\echo 'Database initialization completed successfully!'

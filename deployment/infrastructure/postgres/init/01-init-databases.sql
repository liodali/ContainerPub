-- Initialize databases for Dart Cloud Backend
-- This script runs automatically when the container starts for the first time

-- Create functions database
CREATE DATABASE functions_db;

-- Grant privileges to the main user
GRANT ALL PRIVILEGES ON DATABASE dart_cloud TO dart_cloud;
GRANT ALL PRIVILEGES ON DATABASE functions_db TO dart_cloud;

-- Connect to dart_cloud database
\c dart_cloud;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create functions table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS functions (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    active_deployment_id INTEGER,
    analysis_result JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, name)
);

-- Create function_deployments table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS function_deployments (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    image_tag VARCHAR(255) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    status VARCHAR(50) DEFAULT 'building',
    is_active BOOLEAN DEFAULT false,
    build_logs TEXT,
    deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(function_id, version)
);

-- Create function_logs table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS function_logs (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
-- UUID indexes for client-facing queries
CREATE INDEX IF NOT EXISTS idx_users_uuid ON users(uuid);
CREATE INDEX IF NOT EXISTS idx_functions_uuid ON functions(uuid);
CREATE INDEX IF NOT EXISTS idx_function_deployments_uuid ON function_deployments(uuid);
CREATE INDEX IF NOT EXISTS idx_function_logs_uuid ON function_logs(uuid);

-- Email index for authentication
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Foreign key indexes for fast joins
CREATE INDEX IF NOT EXISTS idx_functions_user_id ON functions(user_id);
CREATE INDEX IF NOT EXISTS idx_functions_active_deployment ON functions(active_deployment_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_function_id ON function_deployments(function_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_is_active ON function_deployments(function_id, is_active);
CREATE INDEX IF NOT EXISTS idx_function_deployments_version ON function_deployments(function_id, version DESC);
CREATE INDEX IF NOT EXISTS idx_function_logs_function_id ON function_logs(function_id);

-- Timestamp indexes for time-based queries
CREATE INDEX IF NOT EXISTS idx_function_logs_timestamp ON function_logs(timestamp DESC);

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
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_functions_updated_at ON functions;
CREATE TRIGGER update_functions_updated_at BEFORE UPDATE ON functions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Connect to functions_db database
\c functions_db;

-- Create tables for function-specific data storage
CREATE TABLE IF NOT EXISTS function_data (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_id INTEGER NOT NULL,
    key VARCHAR(255) NOT NULL,
    value JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(function_id, key)
);

CREATE INDEX IF NOT EXISTS idx_function_data_uuid ON function_data(uuid);
CREATE INDEX IF NOT EXISTS idx_function_data_function_id ON function_data(function_id);
CREATE INDEX IF NOT EXISTS idx_function_data_key ON function_data(key);

-- Grant privileges on functions_db
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dart_cloud;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dart_cloud;

-- Switch back to dart_cloud database
\c dart_cloud;

-- Grant privileges on dart_cloud
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dart_cloud;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dart_cloud;

-- Print success message
SELECT 'Database initialization completed successfully!' AS status;

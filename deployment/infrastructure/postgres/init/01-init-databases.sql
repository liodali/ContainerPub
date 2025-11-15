-- Initialize databases for Dart Cloud Backend
-- This script runs automatically when the container starts for the first time

-- Create functions database
CREATE DATABASE functions_db;

-- Grant privileges to the main user
GRANT ALL PRIVILEGES ON DATABASE dart_cloud TO dart_cloud;
GRANT ALL PRIVILEGES ON DATABASE functions_db TO dart_cloud;

-- Connect to dart_cloud database
\c dart_cloud;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create functions table
CREATE TABLE IF NOT EXISTS functions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    runtime VARCHAR(50) DEFAULT 'dart',
    status VARCHAR(50) DEFAULT 'active',
    active_deployment_id UUID,
    environment JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_invoked_at TIMESTAMP,
    invocation_count INTEGER DEFAULT 0,
    UNIQUE(user_id, name)
);

-- Create function_deployments table for deployment history
CREATE TABLE IF NOT EXISTS function_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    function_id UUID NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    image_tag VARCHAR(255) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    status VARCHAR(50) DEFAULT 'building',
    is_active BOOLEAN DEFAULT false,
    build_logs TEXT,
    deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(function_id, version)
);

-- Create function_logs table
CREATE TABLE IF NOT EXISTS function_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    function_id UUID NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_functions_user_id ON functions(user_id);
CREATE INDEX IF NOT EXISTS idx_functions_name ON functions(name);
CREATE INDEX IF NOT EXISTS idx_functions_active_deployment ON functions(active_deployment_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_function_id ON function_deployments(function_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_is_active ON function_deployments(function_id, is_active);
CREATE INDEX IF NOT EXISTS idx_function_deployments_version ON function_deployments(function_id, version DESC);
CREATE INDEX IF NOT EXISTS idx_function_logs_function_id ON function_logs(function_id);
CREATE INDEX IF NOT EXISTS idx_function_logs_created_at ON function_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_functions_updated_at BEFORE UPDATE ON functions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Connect to functions_db database
\c functions_db;

-- Create tables for function-specific data storage
CREATE TABLE IF NOT EXISTS function_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    function_id UUID NOT NULL,
    key VARCHAR(255) NOT NULL,
    value JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(function_id, key)
);

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

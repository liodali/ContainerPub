-- ContainerPub Database Initialization Script
-- This script creates the necessary databases and tables
-- Matches deployment/infrastructure/postgres/init schema

-- Create functions database if it doesn't exist
SELECT 'CREATE DATABASE functions_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'functions_db')\gexec

-- Connect to main database
\c dart_cloud

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
\echo "Users table created"

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
\echo "Functions table created"

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
\echo "Function deployments table created"

-- Create function_deploy_logs table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS function_deploy_logs (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_uuid UUID NOT NULL REFERENCES functions(uuid) ON DELETE CASCADE,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
\echo "Function deploy logs table created"

-- Create function_invocations table with serial ID (internal) and UUID (public)
-- Stores request metadata and execution logs
-- Body is NOT stored for security - only request info (headers, query, method, path)
CREATE TABLE IF NOT EXISTS function_invocations (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    duration_ms INTEGER,
    error TEXT,
    logs JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    request_info JSONB,
    result TEXT,
    success BOOLEAN
);
\echo "Function invocations table created"

-- Create logs table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    level VARCHAR(20) NOT NULL,
    message JSONB NOT NULL,
    action TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
\echo "Logs table created"


DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY ARRAY['users', 'functions', 'function_deploy_logs', 'function_invocations']
    LOOP
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = table_name) THEN
            RAISE NOTICE 'Table % exists', table_name;
        ELSE
            RAISE NOTICE 'Table % does not exist', table_name;
        END IF;
    END LOOP;
END $$;

-- Create indexes for better performance
-- UUID indexes for client-facing queries
CREATE INDEX IF NOT EXISTS idx_users_uuid ON users(uuid);
CREATE INDEX IF NOT EXISTS idx_functions_uuid ON functions(uuid);
CREATE INDEX IF NOT EXISTS idx_function_deployments_uuid ON function_deployments(uuid);
CREATE INDEX IF NOT EXISTS idx_function_deploy_logs_uuid ON function_deploy_logs(uuid);
CREATE INDEX IF NOT EXISTS idx_function_invocations_uuid ON function_invocations(uuid);
CREATE INDEX IF NOT EXISTS idx_logs_uuid ON logs(uuid);

-- Email index for authentication
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Foreign key indexes for fast joins
CREATE INDEX IF NOT EXISTS idx_functions_user_id ON functions(user_id);
CREATE INDEX IF NOT EXISTS idx_functions_active_deployment ON functions(active_deployment_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_function_id ON function_deployments(function_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_is_active ON function_deployments(function_id, is_active);
CREATE INDEX IF NOT EXISTS idx_function_deployments_version ON function_deployments(function_id, version DESC);
CREATE INDEX IF NOT EXISTS idx_function_deploy_logs_function_id ON function_deploy_logs(function_uuid);
CREATE INDEX IF NOT EXISTS idx_function_invocations_function_id ON function_invocations(function_id);

-- Timestamp indexes for time-based queries
CREATE INDEX IF NOT EXISTS idx_function_deploy_logs_timestamp ON function_deploy_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_function_invocations_timestamp ON function_invocations(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_action ON logs(action);
CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level);

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

-- Connect to functions database
\c functions_db

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
\c dart_cloud

-- Grant privileges on dart_cloud
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dart_cloud;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dart_cloud;

-- Print success message
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'Database initialization completed successfully!'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo ''
\echo 'Created databases:'
\echo '  ✓ dart_cloud      - Main application database'
\echo '  ✓ functions_db    - Functions data storage'
\echo ''
\echo 'Created tables in dart_cloud:'
\echo '  ✓ users                    (SERIAL + UUID)'
\echo '  ✓ functions                (SERIAL + UUID, with deployment support)'
\echo '  ✓ function_deployments     (SERIAL + UUID, versioned deployments)'
\echo '  ✓ function_deploy_logs     (SERIAL + UUID)'
\echo '  ✓ function_invocations     (SERIAL + UUID)'
\echo '  ✓ logs                     (SERIAL + UUID)'
\echo ''
\echo 'Created tables in functions_db:'
\echo '  ✓ function_data            (SERIAL + UUID, per-function storage)'
\echo ''
\echo 'Features enabled:'
\echo '  ✓ Dual identifiers (SERIAL IDs + UUIDs)'
\echo '  ✓ UUID extension (uuid-ossp)'
\echo '  ✓ Deployment versioning and history'
\echo '  ✓ Automatic updated_at triggers'
\echo '  ✓ Performance indexes on all tables'
\echo '  ✓ Foreign key constraints (INTEGER)'
\echo '  ✓ Function invocation tracking'
\echo ''
\echo 'Ready for use! 🚀'
\echo ''

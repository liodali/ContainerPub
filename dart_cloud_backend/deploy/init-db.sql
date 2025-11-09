-- ContainerPub Database Initialization Script
-- This script creates the necessary databases and tables
-- Uses dual-identifier approach: SERIAL IDs (internal) + UUIDs (public)

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
    analysis_result JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, name)
);
\echo "Functions table created"

-- Create function_logs table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS function_logs (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
\echo "Function logs table created"

-- Create function_invocations table with serial ID (internal) and UUID (public)
CREATE TABLE IF NOT EXISTS function_invocations (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    duration_ms INTEGER,
    error TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
\echo "Function invocations table created"

-- Create indexes for better performance
-- UUID indexes for client-facing queries
CREATE INDEX IF NOT EXISTS idx_users_uuid ON users(uuid);
CREATE INDEX IF NOT EXISTS idx_functions_uuid ON functions(uuid);
CREATE INDEX IF NOT EXISTS idx_function_logs_uuid ON function_logs(uuid);
CREATE INDEX IF NOT EXISTS idx_function_invocations_uuid ON function_invocations(uuid);

-- Email index for authentication
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Foreign key indexes for fast joins
CREATE INDEX IF NOT EXISTS idx_functions_user_id ON functions(user_id);
CREATE INDEX IF NOT EXISTS idx_function_logs_function_id ON function_logs(function_id);
CREATE INDEX IF NOT EXISTS idx_function_invocations_function_id ON function_invocations(function_id);

-- Timestamp indexes for time-based queries
CREATE INDEX IF NOT EXISTS idx_function_logs_timestamp ON function_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_function_invocations_timestamp ON function_invocations(timestamp DESC);

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

-- Enable UUID extension in functions_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create function_data table for user functions to store data
CREATE TABLE IF NOT EXISTS function_data (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    key VARCHAR(255) NOT NULL,
    value JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(key)
);

-- Create indexes for function_data
CREATE INDEX IF NOT EXISTS idx_function_data_uuid ON function_data(uuid);
CREATE INDEX IF NOT EXISTS idx_function_data_key ON function_data(key);

-- Create updated_at trigger function for functions_db
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

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
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'Database initialization completed successfully!'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo ''
\echo 'Created databases:'
\echo '  ✓ dart_cloud      - Main application database'
\echo '  ✓ functions_db    - Functions data storage'
\echo ''
\echo 'Created tables in dart_cloud:'
\echo '  ✓ users                    (with UUID support)'
\echo '  ✓ functions                (with UUID support)'
\echo '  ✓ function_logs            (with UUID support)'
\echo '  ✓ function_invocations     (with UUID support)'
\echo ''
\echo 'Created tables in functions_db:'
\echo '  ✓ function_data            (with UUID support)'
\echo ''
\echo 'Features enabled:'
\echo '  ✓ UUID extension (uuid-ossp)'
\echo '  ✓ Dual identifiers (SERIAL IDs + UUIDs)'
\echo '  ✓ Automatic updated_at triggers'
\echo '  ✓ Performance indexes on all tables'
\echo '  ✓ Foreign key constraints'
\echo ''
\echo 'Security notes:'
\echo '  • Serial IDs are for internal use only'
\echo '  • UUIDs are for client-facing operations'
\echo '  • Never expose serial IDs in APIs'
\echo ''
\echo 'Ready for use! 🚀'
\echo ''

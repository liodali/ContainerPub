-- Initialize databases for ContainerPub

-- Create functions database
CREATE DATABASE functions_db;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE functions_db TO dart_cloud;

-- Connect to functions_db and create test table
\c functions_db

CREATE TABLE IF NOT EXISTS items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO items (name) VALUES 
  ('Test Item 1'),
  ('Test Item 2'),
  ('Test Item 3')
ON CONFLICT DO NOTHING;

-- Grant privileges on tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dart_cloud;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dart_cloud;

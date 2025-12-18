-- Migration: Rename function_logs table to function_deploy_logs
-- Version: 005
-- Description: Renames function_logs table to function_deploy_logs for clarity

-- Drop existing indexes
DROP INDEX IF EXISTS idx_function_logs_function_id;
DROP INDEX IF EXISTS idx_function_logs_timestamp;

-- Rename table
ALTER TABLE function_logs RENAME TO function_deploy_logs;

-- Recreate indexes with new table name
CREATE INDEX IF NOT EXISTS idx_function_deploy_logs_function_id ON function_deploy_logs(function_uuid);
CREATE INDEX IF NOT EXISTS idx_function_deploy_logs_timestamp ON function_deploy_logs(timestamp DESC);

\echo 'Migration 005: Renamed function_logs table to function_deploy_logs'

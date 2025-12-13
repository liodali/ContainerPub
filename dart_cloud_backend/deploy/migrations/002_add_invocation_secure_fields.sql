-- Migration: Add request info and execution logs to function_invocations table
-- Version: 002
-- Description: Adds request_info, result, success, and logs columns
--              Body is NOT stored for security - only request metadata

-- Add new columns to function_invocations table
ALTER TABLE function_invocations 
    ADD COLUMN IF NOT EXISTS request_info JSONB,
    ADD COLUMN IF NOT EXISTS result TEXT,
    ADD COLUMN IF NOT EXISTS success BOOLEAN,
    ADD COLUMN IF NOT EXISTS logs JSONB;

-- Drop old columns if they exist (no longer used)
ALTER TABLE function_invocations 
    DROP COLUMN IF EXISTS request_body,
    DROP COLUMN IF EXISTS request_raw,
    DROP COLUMN IF EXISTS request_headers,
    DROP COLUMN IF EXISTS request_query;

-- Add comment explaining the security model
COMMENT ON COLUMN function_invocations.request_info IS 'Request metadata (headers, query, method, path) - no body for security';
COMMENT ON COLUMN function_invocations.result IS 'Base64 encoded function result - protected for future encryption';
COMMENT ON COLUMN function_invocations.error IS 'Base64 encoded error message - protected for future encryption';
COMMENT ON COLUMN function_invocations.success IS 'Boolean indicating if function execution was successful';
COMMENT ON COLUMN function_invocations.logs IS 'JSONB structured logs with container output and execution errors';

\echo 'Migration 002: Added request info and execution logs to function_invocations table'

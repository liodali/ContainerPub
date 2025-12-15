-- Migration: Add API keys table for function signing
-- Version: 003
-- Description: Creates api_keys table for storing public keys and key metadata
--              Private keys are returned only once at creation and stored by CLI

-- Create api_keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    function_uuid UUID NOT NULL REFERENCES functions(uuid) ON DELETE CASCADE,
    public_key TEXT NOT NULL,
    private_key_hash VARCHAR(255),
    validity VARCHAR(20) NOT NULL CHECK (validity IN ('1h', '1d', '1w', '1m', 'forever')),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for api_keys table
CREATE INDEX IF NOT EXISTS idx_api_keys_uuid ON api_keys(uuid);
CREATE INDEX IF NOT EXISTS idx_api_keys_function_uuid ON api_keys(function_uuid);
CREATE INDEX IF NOT EXISTS idx_api_keys_is_active ON api_keys(is_active);
CREATE INDEX IF NOT EXISTS idx_api_keys_expires_at ON api_keys(expires_at);

-- Add comments explaining the security model
COMMENT ON TABLE api_keys IS 'API keys for function invocation signing - public keys stored, private keys returned once';
COMMENT ON COLUMN api_keys.public_key IS 'Public key used to verify request signatures';
COMMENT ON COLUMN api_keys.private_key_hash IS 'Hash of private key for revocation verification';
COMMENT ON COLUMN api_keys.validity IS 'Key validity duration: 1h, 1d, 1w, 1m, or forever';
COMMENT ON COLUMN api_keys.expires_at IS 'Expiration timestamp - NULL for forever keys';
COMMENT ON COLUMN api_keys.is_active IS 'Whether the key is active - set to false on revocation';
COMMENT ON COLUMN api_keys.revoked_at IS 'Timestamp when key was revoked';

\echo 'Migration 003: Added api_keys table for function signing'

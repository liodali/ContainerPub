-- Migration: Alter logs table schema
-- Version: 004
-- Description: Changes message column from TEXT to JSONB and action column from VARCHAR to TEXT

-- Alter message column to JSONB
ALTER TABLE logs
ALTER COLUMN message TYPE JSONB USING message::JSONB;

-- Alter action column to TEXT
ALTER TABLE logs
ALTER COLUMN action TYPE TEXT;

\echo 'Migration 004: Altered logs table - message to JSONB, action to TEXT'

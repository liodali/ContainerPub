-- Migration: Add deployment versioning and history
-- Run this on existing databases to migrate to the new schema

\c dart_cloud;

-- Create function_deployments table if it doesn't exist
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

-- Add status column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='functions' AND column_name='status') THEN
        ALTER TABLE functions ADD COLUMN status VARCHAR(50) DEFAULT 'active';
    END IF;
END $$;

-- Add active_deployment_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='functions' AND column_name='active_deployment_id') THEN
        ALTER TABLE functions ADD COLUMN active_deployment_id INTEGER;
    END IF;
END $$;

-- Migrate existing functions with image_tag and s3_key to deployments table
DO $$ 
DECLARE
    func_record RECORD;
    new_deployment_id INTEGER;
BEGIN
    -- Check if old columns exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='functions' AND column_name='image_tag') THEN
        
        -- Migrate existing data
        FOR func_record IN 
            SELECT id, image_tag, s3_key 
            FROM functions 
            WHERE image_tag IS NOT NULL
        LOOP
            -- Create deployment record (will be assigned by SERIAL)
            
            INSERT INTO function_deployments 
                (function_id, version, image_tag, s3_key, status, is_active)
            VALUES 
                (func_record.id, 1, func_record.image_tag, 
                 COALESCE(func_record.s3_key, 'functions/' || func_record.id || '/function.tar.gz'), 
                 'active', true)
            RETURNING id INTO new_deployment_id;
            
            -- Update function with active deployment
            UPDATE functions 
            SET active_deployment_id = new_deployment_id 
            WHERE id = func_record.id;
        END LOOP;
        
        -- Drop old columns
        ALTER TABLE functions DROP COLUMN IF EXISTS image_tag;
        ALTER TABLE functions DROP COLUMN IF EXISTS s3_key;
    END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_function_deployments_uuid ON function_deployments(uuid);
CREATE INDEX IF NOT EXISTS idx_functions_active_deployment ON functions(active_deployment_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_function_id ON function_deployments(function_id);
CREATE INDEX IF NOT EXISTS idx_function_deployments_is_active ON function_deployments(function_id, is_active);
CREATE INDEX IF NOT EXISTS idx_function_deployments_version ON function_deployments(function_id, version DESC);

SELECT 'Migration completed: Deployment versioning and history added successfully!' AS status;

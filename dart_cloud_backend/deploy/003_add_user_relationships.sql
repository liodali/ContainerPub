-- Migration: Add User Relationships (User Information, Organizations, Members)
-- Version: 003
-- Description: Creates tables for user information, organizations, and organization members
-- Updated: Removed teams concept - one organization can have multiple users

-- ============================================
-- User Information Table
-- ============================================
CREATE TABLE IF NOT EXISTS user_information (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    country VARCHAR(100),
    city VARCHAR(100),
    address TEXT,
    zip_code VARCHAR(20),
    avatar TEXT,
    role VARCHAR(50) NOT NULL CHECK (role IN ('developer', 'team', 'sub_team_developer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_information_user_id ON user_information(user_id);
CREATE INDEX IF NOT EXISTS idx_user_information_role ON user_information(role);

-- ============================================
-- Organizations Table
-- ============================================
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
    name VARCHAR(255) UNIQUE NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_organizations_owner_id ON organizations(owner_id);
CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name);

-- ============================================
-- Organization Members Table (Junction Table)
-- ============================================
-- Links users to organizations (one user can only belong to one organization)
CREATE TABLE IF NOT EXISTS organization_members (
    id SERIAL PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES organizations(uuid) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON organization_members(user_id);

-- ============================================
-- Triggers for updated_at
-- ============================================

-- User Information updated_at trigger
CREATE OR REPLACE FUNCTION update_user_information_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_information_updated_at
    BEFORE UPDATE ON user_information
    FOR EACH ROW
    EXECUTE FUNCTION update_user_information_updated_at();

-- Organizations updated_at trigger
CREATE OR REPLACE FUNCTION update_organizations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION update_organizations_updated_at();


-- ============================================
-- Comments for documentation
-- ============================================

COMMENT ON TABLE user_information IS 'Stores additional information about users including name, contact details, and role';
COMMENT ON TABLE organizations IS 'Organizations that can have multiple users. Organization names must be unique.';
COMMENT ON TABLE organization_members IS 'Junction table linking users to organizations. Each user can only belong to one organization.';

COMMENT ON COLUMN user_information.role IS 'User role: developer, team, or sub_team_developer';
COMMENT ON COLUMN user_information.user_id IS 'Foreign key to users table (one-to-one relationship)';
COMMENT ON COLUMN organizations.owner_id IS 'Foreign key to users table - organization owner';
COMMENT ON COLUMN organizations.name IS 'Organization name - must be unique across all organizations';
COMMENT ON COLUMN organization_members.organization_id IS 'Foreign key to organizations table';
COMMENT ON COLUMN organization_members.user_id IS 'Foreign key to users table - unique constraint ensures one user = one organization';

-- ============================================
-- Create Mobile App Tables
-- ============================================
-- This migration creates all tables needed by the mobile app
-- for activities, maintenance jobs, and inventory photos

-- ============================================
-- 1. Mobile Activities Table
-- ============================================
-- Stores all check-in/check-out and other activities from mobile app

CREATE TABLE IF NOT EXISTS mobile_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    vehicle_number TEXT NOT NULL,
    activity_type TEXT NOT NULL, -- 'check_in', 'check_out', 'inspection', etc.
    user_name TEXT,
    user_email TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Foreign key to crm_vehicles
    CONSTRAINT fk_mobile_activities_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_mobile_activities_vehicle_id ON mobile_activities(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_activities_timestamp ON mobile_activities(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_mobile_activities_type ON mobile_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_mobile_activities_user ON mobile_activities(user_email);

-- Add comments
COMMENT ON TABLE mobile_activities IS 'Stores all activities performed from the mobile app (check-in, check-out, inspections, etc.)';
COMMENT ON COLUMN mobile_activities.activity_type IS 'Type of activity: check_in, check_out, inspection, maintenance, etc.';
COMMENT ON COLUMN mobile_activities.metadata IS 'JSON object containing activity details (battery_percentage, charging_type, issues_reported, etc.)';

-- ============================================
-- 2. Mobile Maintenance Jobs Table
-- ============================================
-- Stores maintenance jobs created from mobile app

CREATE TABLE IF NOT EXISTS mobile_maintenance_jobs (
    job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    job_category TEXT DEFAULT 'issue', -- 'issue', 'maintenance', 'inspection'
    issue_type TEXT,
    description TEXT,
    diagnosis_date TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending_diagnosis', -- 'pending_diagnosis', 'in_progress', 'completed', 'cancelled'
    priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    assigned_to TEXT,
    photo_url TEXT,
    video_url TEXT,
    resolution_notes TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Foreign key to crm_vehicles
    CONSTRAINT fk_mobile_maintenance_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_vehicle_id ON mobile_maintenance_jobs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_status ON mobile_maintenance_jobs(status);
CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_date ON mobile_maintenance_jobs(diagnosis_date DESC);
CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_type ON mobile_maintenance_jobs(issue_type);

-- Add comments
COMMENT ON TABLE mobile_maintenance_jobs IS 'Maintenance jobs and issues reported from the mobile app';
COMMENT ON COLUMN mobile_maintenance_jobs.job_category IS 'Category: issue (problem found), maintenance (scheduled), inspection (from checklist)';
COMMENT ON COLUMN mobile_maintenance_jobs.status IS 'Current status: pending_diagnosis, in_progress, completed, cancelled';

-- ============================================
-- 3. Mobile Inventory Photos Table
-- ============================================
-- Stores inventory photos captured from mobile app

CREATE TABLE IF NOT EXISTS mobile_inventory_photos (
    photo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    category TEXT NOT NULL, -- 'exterior_front', 'exterior_rear', 'interior_cabin', etc.
    photo_url TEXT NOT NULL,
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    captured_by TEXT,
    activity_type TEXT, -- 'check_in', 'check_out', 'inspection'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Foreign key to crm_vehicles
    CONSTRAINT fk_mobile_photos_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mobile_photos_vehicle_id ON mobile_inventory_photos(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_photos_category ON mobile_inventory_photos(category);
CREATE INDEX IF NOT EXISTS idx_mobile_photos_date ON mobile_inventory_photos(captured_at DESC);

-- Add comments
COMMENT ON TABLE mobile_inventory_photos IS 'Inventory photos captured during check-in/check-out from mobile app';
COMMENT ON COLUMN mobile_inventory_photos.category IS 'Photo category: exterior_front, exterior_rear, interior_cabin, tool_kit, etc.';

-- ============================================
-- 4. Mobile Daily Inventory Table
-- ============================================
-- Stores daily inventory check results

CREATE TABLE IF NOT EXISTS mobile_daily_inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    check_date DATE NOT NULL,
    status TEXT DEFAULT 'completed', -- 'pending', 'in_progress', 'completed'
    notes JSONB DEFAULT '{}'::jsonb, -- Stores inspection checklist results
    checked_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Foreign key to crm_vehicles
    CONSTRAINT fk_mobile_inventory_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE,
    
    -- Unique constraint: one inventory per vehicle per day
    CONSTRAINT unique_daily_inventory UNIQUE (vehicle_id, check_date)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mobile_inventory_vehicle_id ON mobile_daily_inventory(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_inventory_date ON mobile_daily_inventory(check_date DESC);

-- Add comments
COMMENT ON TABLE mobile_daily_inventory IS 'Daily inventory checks performed from mobile app';
COMMENT ON COLUMN mobile_daily_inventory.notes IS 'JSON object containing inspection checklist results';

-- ============================================
-- 5. Triggers for automatic timestamp updates
-- ============================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to mobile_maintenance_jobs
DROP TRIGGER IF EXISTS update_mobile_maintenance_updated_at ON mobile_maintenance_jobs;
CREATE TRIGGER update_mobile_maintenance_updated_at
    BEFORE UPDATE ON mobile_maintenance_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE mobile_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_maintenance_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_inventory_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_daily_inventory ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all records
CREATE POLICY "Allow authenticated users to read activities"
ON mobile_activities FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to insert activities"
ON mobile_activities FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read maintenance jobs"
ON mobile_maintenance_jobs FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to insert maintenance jobs"
ON mobile_maintenance_jobs FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update maintenance jobs"
ON mobile_maintenance_jobs FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read photos"
ON mobile_inventory_photos FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to insert photos"
ON mobile_inventory_photos FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read inventory"
ON mobile_daily_inventory FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to insert inventory"
ON mobile_daily_inventory FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update inventory"
ON mobile_daily_inventory FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- ============================================
-- Verification Queries
-- ============================================

-- Check if tables were created
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- AND table_name LIKE 'mobile_%'
-- ORDER BY table_name;

-- Check table structures
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'mobile_activities'
-- ORDER BY ordinal_position;

-- Test insert (uncomment to test)
-- INSERT INTO mobile_activities (
--     vehicle_id, vehicle_number, activity_type, user_name, metadata
-- ) VALUES (
--     'test-vehicle-id',
--     'MH-12-AB-1234',
--     'check_out',
--     'Test User',
--     '{"battery_percentage": 85, "charging_type": "AC"}'::jsonb
-- );

-- Verify insert
-- SELECT * FROM mobile_activities ORDER BY timestamp DESC LIMIT 5;

-- ============================================
-- SAFE VERSION: Create Mobile App Tables
-- ============================================
-- This version creates tables WITHOUT foreign keys first,
-- then adds foreign keys after to avoid dependency issues

-- ============================================
-- 1. Mobile Activities Table
-- ============================================

CREATE TABLE IF NOT EXISTS mobile_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    vehicle_number TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    user_name TEXT,
    user_email TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mobile_activities_vehicle_id ON mobile_activities(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_activities_timestamp ON mobile_activities(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_mobile_activities_type ON mobile_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_mobile_activities_user ON mobile_activities(user_email);

-- ============================================
-- 2. Mobile Maintenance Jobs Table
-- ============================================

CREATE TABLE IF NOT EXISTS mobile_maintenance_jobs (
    job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    job_category TEXT DEFAULT 'issue',
    issue_type TEXT,
    description TEXT,
    diagnosis_date TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending_diagnosis',
    priority TEXT DEFAULT 'medium',
    assigned_to TEXT,
    photo_url TEXT,
    video_url TEXT,
    resolution_notes TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_vehicle_id ON mobile_maintenance_jobs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_status ON mobile_maintenance_jobs(status);
CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_date ON mobile_maintenance_jobs(diagnosis_date DESC);
CREATE INDEX IF NOT EXISTS idx_mobile_maintenance_type ON mobile_maintenance_jobs(issue_type);

-- ============================================
-- 3. Mobile Inventory Photos Table
-- ============================================

CREATE TABLE IF NOT EXISTS mobile_inventory_photos (
    photo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    category TEXT NOT NULL,
    photo_url TEXT NOT NULL,
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    captured_by TEXT,
    activity_type TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mobile_photos_vehicle_id ON mobile_inventory_photos(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_photos_category ON mobile_inventory_photos(category);
CREATE INDEX IF NOT EXISTS idx_mobile_photos_date ON mobile_inventory_photos(captured_at DESC);

-- ============================================
-- 4. Mobile Daily Inventory Table
-- ============================================

CREATE TABLE IF NOT EXISTS mobile_daily_inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    check_date DATE NOT NULL,
    status TEXT DEFAULT 'completed',
    notes JSONB DEFAULT '{}'::jsonb,
    checked_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_daily_inventory UNIQUE (vehicle_id, check_date)
);

CREATE INDEX IF NOT EXISTS idx_mobile_inventory_vehicle_id ON mobile_daily_inventory(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_inventory_date ON mobile_daily_inventory(check_date DESC);

-- ============================================
-- 5. Add Foreign Keys (After tables exist)
-- ============================================

-- Add foreign key to mobile_activities
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_mobile_activities_vehicle'
    ) THEN
        ALTER TABLE mobile_activities
        ADD CONSTRAINT fk_mobile_activities_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key to mobile_maintenance_jobs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_mobile_maintenance_vehicle'
    ) THEN
        ALTER TABLE mobile_maintenance_jobs
        ADD CONSTRAINT fk_mobile_maintenance_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key to mobile_inventory_photos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_mobile_photos_vehicle'
    ) THEN
        ALTER TABLE mobile_inventory_photos
        ADD CONSTRAINT fk_mobile_photos_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key to mobile_daily_inventory
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_mobile_inventory_vehicle'
    ) THEN
        ALTER TABLE mobile_daily_inventory
        ADD CONSTRAINT fk_mobile_inventory_vehicle 
        FOREIGN KEY (vehicle_id) 
        REFERENCES crm_vehicles(vehicle_id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- ============================================
-- 6. Triggers
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_mobile_maintenance_updated_at ON mobile_maintenance_jobs;
CREATE TRIGGER update_mobile_maintenance_updated_at
    BEFORE UPDATE ON mobile_maintenance_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 7. Row Level Security (RLS) Policies
-- ============================================

ALTER TABLE mobile_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_maintenance_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_inventory_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_daily_inventory ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to read activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow authenticated users to insert activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow authenticated users to read maintenance jobs" ON mobile_maintenance_jobs;
DROP POLICY IF EXISTS "Allow authenticated users to insert maintenance jobs" ON mobile_maintenance_jobs;
DROP POLICY IF EXISTS "Allow authenticated users to update maintenance jobs" ON mobile_maintenance_jobs;
DROP POLICY IF EXISTS "Allow authenticated users to read photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow authenticated users to insert photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow authenticated users to read inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow authenticated users to insert inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow authenticated users to update inventory" ON mobile_daily_inventory;

-- Create policies
CREATE POLICY "Allow authenticated users to read activities"
ON mobile_activities FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert activities"
ON mobile_activities FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read maintenance jobs"
ON mobile_maintenance_jobs FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert maintenance jobs"
ON mobile_maintenance_jobs FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update maintenance jobs"
ON mobile_maintenance_jobs FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read photos"
ON mobile_inventory_photos FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert photos"
ON mobile_inventory_photos FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read inventory"
ON mobile_daily_inventory FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert inventory"
ON mobile_daily_inventory FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update inventory"
ON mobile_daily_inventory FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- ============================================
-- Success Message
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Mobile app tables created successfully!';
    RAISE NOTICE '   - mobile_activities';
    RAISE NOTICE '   - mobile_maintenance_jobs';
    RAISE NOTICE '   - mobile_inventory_photos';
    RAISE NOTICE '   - mobile_daily_inventory';
END $$;

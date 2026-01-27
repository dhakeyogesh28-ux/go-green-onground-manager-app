-- ============================================
-- CLEAN SETUP: Drop and Recreate Everything
-- ============================================
-- This script will:
-- 1. Drop existing mobile tables (if they exist)
-- 2. Create fresh tables with correct schema
-- 3. Add all fields to crm_vehicles
-- 4. Fix status constraint
--
-- Safe to run multiple times!
-- ============================================

-- ============================================
-- STEP 1: Drop Existing Mobile Tables
-- ============================================

-- Drop tables in reverse order (to handle foreign keys)
DROP TABLE IF EXISTS mobile_daily_inventory CASCADE;
DROP TABLE IF EXISTS mobile_inventory_photos CASCADE;
DROP TABLE IF EXISTS mobile_maintenance_jobs CASCADE;
DROP TABLE IF EXISTS mobile_activities CASCADE;

-- ============================================
-- STEP 2: Create Mobile App Tables (Fresh)
-- ============================================

-- 2.1: Mobile Activities Table
CREATE TABLE mobile_activities (
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

CREATE INDEX idx_mobile_activities_vehicle_id ON mobile_activities(vehicle_id);
CREATE INDEX idx_mobile_activities_timestamp ON mobile_activities(timestamp DESC);
CREATE INDEX idx_mobile_activities_type ON mobile_activities(activity_type);

-- 2.2: Mobile Maintenance Jobs Table
CREATE TABLE mobile_maintenance_jobs (
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

CREATE INDEX idx_mobile_maintenance_vehicle_id ON mobile_maintenance_jobs(vehicle_id);
CREATE INDEX idx_mobile_maintenance_status ON mobile_maintenance_jobs(status);
CREATE INDEX idx_mobile_maintenance_date ON mobile_maintenance_jobs(diagnosis_date DESC);

-- 2.3: Mobile Inventory Photos Table
CREATE TABLE mobile_inventory_photos (
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

CREATE INDEX idx_mobile_photos_vehicle_id ON mobile_inventory_photos(vehicle_id);
CREATE INDEX idx_mobile_photos_category ON mobile_inventory_photos(category);
CREATE INDEX idx_mobile_photos_date ON mobile_inventory_photos(captured_at DESC);

-- 2.4: Mobile Daily Inventory Table
CREATE TABLE mobile_daily_inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    check_date DATE NOT NULL,
    status TEXT DEFAULT 'completed',
    notes JSONB DEFAULT '{}'::jsonb,
    checked_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_daily_inventory UNIQUE (vehicle_id, check_date)
);

CREATE INDEX idx_mobile_inventory_vehicle_id ON mobile_daily_inventory(vehicle_id);
CREATE INDEX idx_mobile_inventory_date ON mobile_daily_inventory(check_date DESC);

-- ============================================
-- STEP 3: Add Fields to crm_vehicles Table
-- ============================================

-- 3.1: Add battery and charging columns
ALTER TABLE crm_vehicles 
ADD COLUMN IF NOT EXISTS battery_level INTEGER DEFAULT 85,
ADD COLUMN IF NOT EXISTS battery_health INTEGER DEFAULT 85,
ADD COLUMN IF NOT EXISTS last_charge_type TEXT DEFAULT 'AC',
ADD COLUMN IF NOT EXISTS last_charging_type TEXT DEFAULT 'AC';

-- 3.2: Add inspection and inventory columns
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS daily_checks JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS last_inventory_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_inspection_date DATE,
ADD COLUMN IF NOT EXISTS inventory_photo_count INTEGER DEFAULT 0;

-- 3.3: Add check-in/out tracking columns
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS is_vehicle_in BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS last_check_in_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_check_out_time TIMESTAMPTZ;

-- 3.4: Add DC charging counter
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS consecutive_dc_charges INTEGER DEFAULT 0;

-- 3.5: Add service and maintenance tracking
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS last_service_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_service_type TEXT,
ADD COLUMN IF NOT EXISTS service_attention BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS charging_health TEXT DEFAULT 'Good',
ADD COLUMN IF NOT EXISTS to_dos JSONB DEFAULT '[]'::jsonb;

-- 3.6: Add constraints
ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_battery_level_check;
ALTER TABLE crm_vehicles ADD CONSTRAINT crm_vehicles_battery_level_check CHECK (battery_level >= 0 AND battery_level <= 100);

ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_battery_health_check;
ALTER TABLE crm_vehicles ADD CONSTRAINT crm_vehicles_battery_health_check CHECK (battery_health >= 0 AND battery_health <= 100);

ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_charge_type_check;
ALTER TABLE crm_vehicles ADD CONSTRAINT crm_vehicles_charge_type_check CHECK (last_charge_type IN ('AC', 'DC', 'ac', 'dc') OR last_charge_type IS NULL);

-- 3.7: Create indexes
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_is_vehicle_in ON crm_vehicles(is_vehicle_in);
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_battery_level ON crm_vehicles(battery_level);
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_last_inspection_date ON crm_vehicles(last_inspection_date);

-- ============================================
-- STEP 4: Fix Status Constraint
-- ============================================

ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_status_check;

ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_status_check 
CHECK (status IN ('active', 'inactive', 'scrapped', 'trial', 'charging', 'maintenance', 'idle'));

-- ============================================
-- STEP 5: Add Foreign Keys
-- ============================================

ALTER TABLE mobile_activities 
ADD CONSTRAINT fk_mobile_activities_vehicle 
FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;

ALTER TABLE mobile_maintenance_jobs 
ADD CONSTRAINT fk_mobile_maintenance_vehicle 
FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;

ALTER TABLE mobile_inventory_photos 
ADD CONSTRAINT fk_mobile_photos_vehicle 
FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;

ALTER TABLE mobile_daily_inventory 
ADD CONSTRAINT fk_mobile_inventory_vehicle 
FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;

-- ============================================
-- STEP 6: Create Triggers
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

CREATE OR REPLACE FUNCTION update_check_in_out_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_vehicle_in = true AND (OLD.is_vehicle_in IS NULL OR OLD.is_vehicle_in = false) THEN
        NEW.last_check_in_time = NOW();
    END IF;
    
    IF NEW.is_vehicle_in = false AND (OLD.is_vehicle_in IS NULL OR OLD.is_vehicle_in = true) THEN
        NEW.last_check_out_time = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_check_in_out_timestamp ON crm_vehicles;
CREATE TRIGGER trg_update_check_in_out_timestamp
    BEFORE UPDATE ON crm_vehicles
    FOR EACH ROW
    EXECUTE FUNCTION update_check_in_out_timestamp();

-- ============================================
-- STEP 7: Row Level Security
-- ============================================

ALTER TABLE mobile_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_maintenance_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_inventory_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_daily_inventory ENABLE ROW LEVEL SECURITY;

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
DROP POLICY IF EXISTS "Allow authenticated users to update vehicle data" ON crm_vehicles;

CREATE POLICY "Allow authenticated users to read activities" ON mobile_activities FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert activities" ON mobile_activities FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated users to read maintenance jobs" ON mobile_maintenance_jobs FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert maintenance jobs" ON mobile_maintenance_jobs FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated users to update maintenance jobs" ON mobile_maintenance_jobs FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated users to read photos" ON mobile_inventory_photos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert photos" ON mobile_inventory_photos FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated users to read inventory" ON mobile_daily_inventory FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert inventory" ON mobile_daily_inventory FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated users to update inventory" ON mobile_daily_inventory FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated users to update vehicle data" ON crm_vehicles FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- ============================================
-- Success Message
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ DATABASE SETUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Created Tables:';
    RAISE NOTICE '  ✅ mobile_activities';
    RAISE NOTICE '  ✅ mobile_maintenance_jobs';
    RAISE NOTICE '  ✅ mobile_inventory_photos';
    RAISE NOTICE '  ✅ mobile_daily_inventory';
    RAISE NOTICE '';
    RAISE NOTICE 'Updated crm_vehicles:';
    RAISE NOTICE '  ✅ Added battery fields';
    RAISE NOTICE '  ✅ Added inspection fields';
    RAISE NOTICE '  ✅ Added check-in/out fields';
    RAISE NOTICE '  ✅ Fixed status constraint';
    RAISE NOTICE '';
    RAISE NOTICE 'Your mobile app is ready to use!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
END $$;

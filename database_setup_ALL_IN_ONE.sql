-- ============================================
-- ALL-IN-ONE: Complete Mobile App Database Setup
-- ============================================
-- This single script does everything in the correct order:
-- 1. Creates mobile app tables
-- 2. Adds fields to crm_vehicles table
-- 3. Fixes status constraint
--
-- Just run this ONE file and you're done!
-- ============================================

-- ============================================
-- PART 1: Create Mobile App Tables
-- ============================================

-- 1.1: Mobile Activities Table
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

-- 1.2: Mobile Maintenance Jobs Table
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

-- 1.3: Mobile Inventory Photos Table
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

-- 1.4: Mobile Daily Inventory Table
CREATE TABLE IF NOT EXISTS mobile_daily_inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL,
    check_date DATE NOT NULL,
    status TEXT DEFAULT 'completed',
    notes JSONB DEFAULT '{}'::jsonb,
    checked_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mobile_inventory_vehicle_id ON mobile_daily_inventory(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_inventory_date ON mobile_daily_inventory(check_date DESC);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'unique_daily_inventory') THEN
        ALTER TABLE mobile_daily_inventory ADD CONSTRAINT unique_daily_inventory UNIQUE (vehicle_id, check_date);
    END IF;
END $$;

-- ============================================
-- PART 2: Add Fields to crm_vehicles Table
-- ============================================

-- 2.1: Add battery and charging columns
ALTER TABLE crm_vehicles 
ADD COLUMN IF NOT EXISTS battery_level INTEGER DEFAULT 85,
ADD COLUMN IF NOT EXISTS battery_health INTEGER DEFAULT 85,
ADD COLUMN IF NOT EXISTS last_charge_type TEXT DEFAULT 'AC',
ADD COLUMN IF NOT EXISTS last_charging_type TEXT DEFAULT 'AC';

-- 2.2: Add inspection and inventory columns
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS daily_checks JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS last_inventory_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_inspection_date DATE,
ADD COLUMN IF NOT EXISTS inventory_photo_count INTEGER DEFAULT 0;

-- 2.3: Add check-in/out tracking columns
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS is_vehicle_in BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS last_check_in_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_check_out_time TIMESTAMPTZ;

-- 2.4: Add DC charging counter
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS consecutive_dc_charges INTEGER DEFAULT 0;

-- 2.5: Add service and maintenance tracking
ALTER TABLE crm_vehicles
ADD COLUMN IF NOT EXISTS last_service_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_service_type TEXT,
ADD COLUMN IF NOT EXISTS service_attention BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS charging_health TEXT DEFAULT 'Good',
ADD COLUMN IF NOT EXISTS to_dos JSONB DEFAULT '[]'::jsonb;

-- 2.6: Add constraints
ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_battery_level_check;
ALTER TABLE crm_vehicles ADD CONSTRAINT crm_vehicles_battery_level_check CHECK (battery_level >= 0 AND battery_level <= 100);

ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_battery_health_check;
ALTER TABLE crm_vehicles ADD CONSTRAINT crm_vehicles_battery_health_check CHECK (battery_health >= 0 AND battery_health <= 100);

ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_charge_type_check;
ALTER TABLE crm_vehicles ADD CONSTRAINT crm_vehicles_charge_type_check CHECK (last_charge_type IN ('AC', 'DC', 'ac', 'dc') OR last_charge_type IS NULL);

-- 2.7: Create indexes
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_is_vehicle_in ON crm_vehicles(is_vehicle_in);
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_battery_level ON crm_vehicles(battery_level);
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_last_inspection_date ON crm_vehicles(last_inspection_date);

-- ============================================
-- PART 3: Fix Status Constraint
-- ============================================

-- Drop old constraint
ALTER TABLE crm_vehicles DROP CONSTRAINT IF EXISTS crm_vehicles_status_check;

-- Add new constraint with all status values
ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_status_check 
CHECK (status IN (
    'active',       -- Checked out / in use
    'inactive',     -- Not in use
    'scrapped',     -- Decommissioned
    'trial',        -- Testing
    'charging',     -- Checked in and charging
    'maintenance',  -- Needs service/repair
    'idle'          -- Available but not in use
));

-- ============================================
-- PART 4: Add Foreign Keys
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_mobile_activities_vehicle') THEN
        ALTER TABLE mobile_activities ADD CONSTRAINT fk_mobile_activities_vehicle 
        FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_mobile_maintenance_vehicle') THEN
        ALTER TABLE mobile_maintenance_jobs ADD CONSTRAINT fk_mobile_maintenance_vehicle 
        FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_mobile_photos_vehicle') THEN
        ALTER TABLE mobile_inventory_photos ADD CONSTRAINT fk_mobile_photos_vehicle 
        FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_mobile_inventory_vehicle') THEN
        ALTER TABLE mobile_daily_inventory ADD CONSTRAINT fk_mobile_inventory_vehicle 
        FOREIGN KEY (vehicle_id) REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE;
    END IF;
END $$;

-- ============================================
-- PART 5: Create Triggers
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
-- PART 6: Row Level Security
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
    RAISE NOTICE '✅ ✅ ✅ DATABASE SETUP COMPLETE! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'Created Tables:';
    RAISE NOTICE '  ✅ mobile_activities';
    RAISE NOTICE '  ✅ mobile_maintenance_jobs';
    RAISE NOTICE '  ✅ mobile_inventory_photos';
    RAISE NOTICE '  ✅ mobile_daily_inventory';
    RAISE NOTICE '';
    RAISE NOTICE 'Updated crm_vehicles with:';
    RAISE NOTICE '  ✅ Battery fields';
    RAISE NOTICE '  ✅ Inspection fields';
    RAISE NOTICE '  ✅ Check-in/out fields';
    RAISE NOTICE '  ✅ Status constraint fixed';
    RAISE NOTICE '';
    RAISE NOTICE 'Your mobile app is ready to use!';
END $$;

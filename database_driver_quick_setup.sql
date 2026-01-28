-- ============================================
-- QUICK START: Driver Management Tables
-- ============================================
-- This is a simplified version for quick setup
-- Run this in Supabase SQL Editor

-- Step 1: Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
    driver_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_name TEXT NOT NULL,
    phone_number TEXT,
    email TEXT,
    license_number TEXT,
    hub_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Create driver_attendance table
CREATE TABLE IF NOT EXISTS driver_attendance (
    attendance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(driver_id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('check_in', 'check_out')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create indexes
CREATE INDEX IF NOT EXISTS idx_drivers_hub_id ON drivers(hub_id);
CREATE INDEX IF NOT EXISTS idx_drivers_is_active ON drivers(is_active);
CREATE INDEX IF NOT EXISTS idx_drivers_name ON drivers(driver_name);
CREATE INDEX IF NOT EXISTS idx_driver_attendance_driver_id ON driver_attendance(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_attendance_vehicle_id ON driver_attendance(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_driver_attendance_timestamp ON driver_attendance(timestamp DESC);

-- Step 4: Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_attendance ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
DROP POLICY IF EXISTS "Allow authenticated users to view drivers" ON drivers;
CREATE POLICY "Allow authenticated users to view drivers"
ON drivers FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert drivers" ON drivers;
CREATE POLICY "Allow authenticated users to insert drivers"
ON drivers FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to update drivers" ON drivers;
CREATE POLICY "Allow authenticated users to update drivers"
ON drivers FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to view attendance" ON driver_attendance;
CREATE POLICY "Allow authenticated users to view attendance"
ON driver_attendance FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert attendance" ON driver_attendance;
CREATE POLICY "Allow authenticated users to insert attendance"
ON driver_attendance FOR INSERT TO authenticated WITH CHECK (true);

-- Step 6: Add sample drivers (OPTIONAL - uncomment to use)
-- INSERT INTO drivers (driver_name, phone_number, email, license_number, is_active)
-- VALUES 
--     ('Rajesh Kumar', '+91 9876543210', 'rajesh.kumar@example.com', 'MH12-20230001', true),
--     ('Amit Sharma', '+91 9876543211', 'amit.sharma@example.com', 'MH12-20230002', true),
--     ('Priya Patel', '+91 9876543212', 'priya.patel@example.com', 'MH12-20230003', true),
--     ('Suresh Reddy', '+91 9876543213', 'suresh.reddy@example.com', 'MH12-20230004', true),
--     ('Vikram Singh', '+91 9876543214', 'vikram.singh@example.com', 'MH12-20230005', true)
-- ON CONFLICT DO NOTHING;

-- Verification: Check if tables were created
SELECT 
    table_name, 
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_name IN ('drivers', 'driver_attendance')
ORDER BY table_name;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Driver management tables created successfully!';
    RAISE NOTICE '📝 To add sample drivers, uncomment the INSERT statement above';
    RAISE NOTICE '🔍 To verify: SELECT * FROM drivers;';
END $$;

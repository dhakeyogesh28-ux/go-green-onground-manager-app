-- ============================================
-- Driver Management Tables Migration
-- ============================================
-- This migration creates tables for driver management and attendance tracking

-- ============================================
-- DRIVERS TABLE
-- ============================================
-- Create drivers table if it doesn't exist
CREATE TABLE IF NOT EXISTS drivers (
    driver_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_name TEXT NOT NULL,
    phone_number TEXT,
    email TEXT,
    license_number TEXT,
    hub_id UUID,  -- Reference to hub (no foreign key constraint - hub management is flexible)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT drivers_name_not_empty CHECK (length(trim(driver_name)) > 0)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_drivers_hub_id ON drivers(hub_id);
CREATE INDEX IF NOT EXISTS idx_drivers_is_active ON drivers(is_active);
CREATE INDEX IF NOT EXISTS idx_drivers_name ON drivers(driver_name);
CREATE INDEX IF NOT EXISTS idx_drivers_phone ON drivers(phone_number);
CREATE INDEX IF NOT EXISTS idx_drivers_license ON drivers(license_number);

-- Add comments
COMMENT ON TABLE drivers IS 'Stores driver information for vehicle assignments';
COMMENT ON COLUMN drivers.driver_id IS 'Unique identifier for the driver';
COMMENT ON COLUMN drivers.driver_name IS 'Full name of the driver';
COMMENT ON COLUMN drivers.phone_number IS 'Contact phone number';
COMMENT ON COLUMN drivers.email IS 'Email address';
COMMENT ON COLUMN drivers.license_number IS 'Driving license number';
COMMENT ON COLUMN drivers.hub_id IS 'UUID reference to the hub where the driver is assigned (flexible - no FK constraint)';
COMMENT ON COLUMN drivers.is_active IS 'Whether the driver is currently active';

-- ============================================
-- DRIVER ATTENDANCE TABLE
-- ============================================
-- Create driver attendance table if it doesn't exist
CREATE TABLE IF NOT EXISTS driver_attendance (
    attendance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(driver_id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('check_in', 'check_out')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT driver_attendance_activity_type_valid CHECK (activity_type IN ('check_in', 'check_out'))
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_driver_attendance_driver_id ON driver_attendance(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_attendance_vehicle_id ON driver_attendance(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_driver_attendance_timestamp ON driver_attendance(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_driver_attendance_activity_type ON driver_attendance(activity_type);

-- Add comments
COMMENT ON TABLE driver_attendance IS 'Tracks driver attendance for check-in and check-out activities';
COMMENT ON COLUMN driver_attendance.attendance_id IS 'Unique identifier for the attendance record';
COMMENT ON COLUMN driver_attendance.driver_id IS 'Reference to the driver';
COMMENT ON COLUMN driver_attendance.vehicle_id IS 'Reference to the vehicle';
COMMENT ON COLUMN driver_attendance.activity_type IS 'Type of activity: check_in or check_out';
COMMENT ON COLUMN driver_attendance.timestamp IS 'When the attendance was marked';
COMMENT ON COLUMN driver_attendance.notes IS 'Optional notes about the attendance';
COMMENT ON COLUMN driver_attendance.metadata IS 'Additional metadata in JSON format';

-- ============================================
-- TRIGGERS
-- ============================================
-- Create or replace function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for drivers table
DROP TRIGGER IF EXISTS trg_drivers_updated_at ON drivers;
CREATE TRIGGER trg_drivers_updated_at
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RLS (Row Level Security) Policies
-- ============================================
-- Enable RLS on drivers table
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to view drivers" ON drivers;
DROP POLICY IF EXISTS "Allow authenticated users to insert drivers" ON drivers;
DROP POLICY IF EXISTS "Allow authenticated users to update drivers" ON drivers;

-- Allow authenticated users to view all drivers
CREATE POLICY "Allow authenticated users to view drivers"
ON drivers
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to insert drivers
CREATE POLICY "Allow authenticated users to insert drivers"
ON drivers
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update drivers
CREATE POLICY "Allow authenticated users to update drivers"
ON drivers
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Enable RLS on driver_attendance table
ALTER TABLE driver_attendance ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to view attendance" ON driver_attendance;
DROP POLICY IF EXISTS "Allow authenticated users to insert attendance" ON driver_attendance;

-- Allow authenticated users to view all attendance records
CREATE POLICY "Allow authenticated users to view attendance"
ON driver_attendance
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to insert attendance records
CREATE POLICY "Allow authenticated users to insert attendance"
ON driver_attendance
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================
-- Uncomment the following to insert sample drivers for testing

-- INSERT INTO drivers (driver_name, phone_number, email, license_number, is_active)
-- VALUES 
--     ('Rajesh Kumar', '+91 9876543210', 'rajesh.kumar@example.com', 'MH12-20230001', true),
--     ('Amit Sharma', '+91 9876543211', 'amit.sharma@example.com', 'MH12-20230002', true),
--     ('Priya Patel', '+91 9876543212', 'priya.patel@example.com', 'MH12-20230003', true),
--     ('Suresh Reddy', '+91 9876543213', 'suresh.reddy@example.com', 'MH12-20230004', true),
--     ('Vikram Singh', '+91 9876543214', 'vikram.singh@example.com', 'MH12-20230005', true)
-- ON CONFLICT DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these queries to verify the migration was successful:

-- Check if drivers table was created
-- SELECT table_name, table_type 
-- FROM information_schema.tables 
-- WHERE table_name IN ('drivers', 'driver_attendance');

-- Check columns in drivers table
-- SELECT column_name, data_type, column_default, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'drivers'
-- ORDER BY ordinal_position;

-- Check columns in driver_attendance table
-- SELECT column_name, data_type, column_default, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'driver_attendance'
-- ORDER BY ordinal_position;

-- Check indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename IN ('drivers', 'driver_attendance');

-- Check RLS policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE tablename IN ('drivers', 'driver_attendance');

-- View sample drivers (if sample data was inserted)
-- SELECT driver_id, driver_name, phone_number, license_number, is_active
-- FROM drivers
-- ORDER BY driver_name;

-- ============================================
-- ROLLBACK (if needed)
-- ============================================
-- Uncomment the following to rollback this migration:

-- DROP TABLE IF EXISTS driver_attendance CASCADE;
-- DROP TABLE IF EXISTS drivers CASCADE;
-- DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

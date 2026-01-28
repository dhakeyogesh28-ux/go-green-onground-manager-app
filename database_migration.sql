-- ============================================
-- Vehicle Status Column Migration
-- ============================================
-- This migration adds the 'status' column to crm_vehicles table
-- and sets up proper constraints for vehicle status management based on admin panel

-- Step 1: Add status column to crm_vehicles table
ALTER TABLE crm_vehicles 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Step 2: Add a check constraint to ensure only valid status values
-- Values matched with Admin Panel Vehicle model and Mobile App requirements
ALTER TABLE crm_vehicles
DROP CONSTRAINT IF EXISTS crm_vehicles_status_check;

ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_status_check 
CHECK (status IN ('active', 'inactive', 'scrapped', 'trial', 'charging', 'maintenance', 'idle'));

-- Step 3: Create an index on status column for better query performance
CREATE INDEX IF NOT EXISTS idx_crm_vehicles_status ON crm_vehicles(status);

-- Step 4: Update existing records to have a default status
UPDATE crm_vehicles 
SET status = 'active' 
WHERE status IS NULL;

-- Step 5: Add a comment to document the column
COMMENT ON COLUMN crm_vehicles.status IS 'Vehicle status: active (checked out/in use), inactive (not in use), scrapped (decommissioned), trial (testing), charging (checked in and charging), maintenance (needs service/repair), idle (available but not in use)';

-- ============================================
-- Verification Queries
-- ============================================
-- Run these queries to verify the migration was successful:

-- Check if column was added successfully
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'crm_vehicles' AND column_name = 'status';

-- Check constraint
-- SELECT constraint_name, check_clause
-- FROM information_schema.check_constraints
-- WHERE constraint_name = 'crm_vehicles_status_check';

-- View current status distribution
-- SELECT status, COUNT(*) as count
-- FROM crm_vehicles
-- GROUP BY status;

-- ============================================
-- Optional: Create a function to log status changes
-- ============================================
CREATE OR REPLACE FUNCTION log_vehicle_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO activities (
            vehicle_id,
            activity_type,
            user_email,
            metadata,
            created_at
        ) VALUES (
            NEW.vehicle_id,
            'status_change',
            current_user,
            jsonb_build_object(
                'old_status', OLD.status,
                'new_status', NEW.status,
                'vehicle_number', NEW.registration_number
            ),
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (optional - only if you want to log status changes)
DROP TRIGGER IF EXISTS trg_vehicle_status_change ON crm_vehicles;
CREATE TRIGGER trg_vehicle_status_change
    AFTER UPDATE ON crm_vehicles
    FOR EACH ROW
    EXECUTE FUNCTION log_vehicle_status_change();

-- ============================================
-- RLS (Row Level Security) Policies
-- ============================================
-- Ensure users can update the status column
-- Note: Adjust these policies based on your security requirements

-- Drop existing policy if it exists, then create new one
DROP POLICY IF EXISTS "Allow authenticated users to update vehicle status" ON crm_vehicles;

-- Allow authenticated users to update vehicle status
CREATE POLICY "Allow authenticated users to update vehicle status"
ON crm_vehicles
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- If you want to restrict updates to specific users/roles, comment out the above
-- and uncomment this instead:
-- DROP POLICY IF EXISTS "Allow hub users to update their vehicles" ON crm_vehicles;
-- CREATE POLICY "Allow hub users to update their vehicles"
-- ON crm_vehicles
-- FOR UPDATE
-- TO authenticated
-- USING (primary_hub_id IN (
--     SELECT hub_id FROM users WHERE email = current_user
-- ))
-- WITH CHECK (true);

-- ============================================
-- Test the migration
-- ============================================
-- Test updating a vehicle status
-- UPDATE crm_vehicles 
-- SET status = 'active' 
-- WHERE vehicle_id = (SELECT vehicle_id FROM crm_vehicles LIMIT 1);

-- Verify the update
-- SELECT vehicle_id, registration_number, status 
-- FROM crm_vehicles 
-- LIMIT 5;

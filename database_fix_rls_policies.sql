-- ============================================
-- FIX: Row-Level Security (RLS) Policies for Mobile Activities
-- ============================================
-- This fixes the "new row violates row-level security policy" error
-- Run this in your Supabase SQL Editor
-- ============================================

-- Step 1: Enable RLS on mobile_activities (if not already enabled)
ALTER TABLE mobile_activities ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies (if any) to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to read activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow authenticated users to insert activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow service role to insert activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow anon to insert activities" ON mobile_activities;

-- Step 3: Create INSERT policy for authenticated users (mobile app users)
CREATE POLICY "Allow authenticated users to insert activities"
ON mobile_activities
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Step 4: Create SELECT policy for authenticated users (to read activities)
CREATE POLICY "Allow authenticated users to read activities"
ON mobile_activities
FOR SELECT
TO authenticated
USING (true);

-- Step 5: Create INSERT policy for service_role (for database triggers)
-- This allows triggers to insert activities even when RLS is enabled
CREATE POLICY "Allow service role to insert activities"
ON mobile_activities
FOR INSERT
TO service_role
WITH CHECK (true);

-- Step 6: Also allow anon role (in case your app uses anon key)
-- Remove this if you only use authenticated users
CREATE POLICY "Allow anon to insert activities"
ON mobile_activities
FOR INSERT
TO anon
WITH CHECK (true);

-- Step 7: Fix the trigger function to use SECURITY DEFINER
-- This allows the trigger to bypass RLS when inserting
DROP TRIGGER IF EXISTS trg_vehicle_status_change ON crm_vehicles;
DROP FUNCTION IF EXISTS log_vehicle_status_change();

CREATE OR REPLACE FUNCTION log_vehicle_status_change()
RETURNS TRIGGER
SECURITY DEFINER  -- This allows the function to bypass RLS
SET search_path = public
AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO mobile_activities (
            vehicle_id,
            vehicle_number,
            activity_type,
            user_email,
            metadata,
            created_at,
            timestamp
        ) VALUES (
            NEW.vehicle_id,
            COALESCE(NEW.registration_number, 'UNKNOWN'),
            'status_change',
            COALESCE(
                current_setting('request.jwt.claims', true)::json->>'email',
                'system'
            ),
            jsonb_build_object(
                'old_status', OLD.status,
                'new_status', NEW.status,
                'vehicle_number', COALESCE(NEW.registration_number, 'UNKNOWN')
            ),
            NOW(),
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER trg_vehicle_status_change
    AFTER UPDATE ON crm_vehicles
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION log_vehicle_status_change();

-- Step 8: Verify policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'mobile_activities';
    
    RAISE NOTICE '✅ RLS policies created for mobile_activities';
    RAISE NOTICE '   Total policies: %', policy_count;
    RAISE NOTICE '   Policies should include: INSERT for authenticated, service_role, and anon';
END $$;

-- ============================================
-- Verification Query (optional - run to check)
-- ============================================
-- SELECT 
--     schemaname,
--     tablename,
--     policyname,
--     permissive,
--     roles,
--     cmd,
--     qual,
--     with_check
-- FROM pg_policies
-- WHERE tablename = 'mobile_activities'
-- ORDER BY policyname;


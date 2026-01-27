-- ============================================
-- Fix RLS Policies for mobile_activities Table
-- ============================================
-- This script ensures that activities can be read and written
-- by both authenticated and anonymous users (for mobile app)
-- ============================================

-- Step 1: Enable RLS on mobile_activities (if not already enabled)
ALTER TABLE mobile_activities ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow authenticated users to insert activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow service role to insert activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow anon to insert activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow anon to read activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow all to read activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow all to insert activities" ON mobile_activities;

-- Step 3: Create permissive policies for both authenticated and anonymous users
-- This allows the mobile app to work without authentication issues

-- Allow ALL users (authenticated + anonymous) to read activities
CREATE POLICY "Allow all to read activities"
ON mobile_activities
FOR SELECT
TO public
USING (true);

-- Allow ALL users (authenticated + anonymous) to insert activities
CREATE POLICY "Allow all to insert activities"
ON mobile_activities
FOR INSERT
TO public
WITH CHECK (true);

-- Step 4: Verify the policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'mobile_activities';
    
    RAISE NOTICE '✅ RLS policies created for mobile_activities';
    RAISE NOTICE '   Total policies: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Policy details:';
    
    FOR policy_record IN 
        SELECT policyname, cmd, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename = 'mobile_activities'
    LOOP
        RAISE NOTICE '   - %: % (qual: %, check: %)', 
            policy_record.policyname, 
            policy_record.cmd,
            policy_record.qual,
            policy_record.with_check;
    END LOOP;
END $$;

-- Step 5: Test by inserting a sample activity (optional - comment out if not needed)
-- DO $$
-- DECLARE
--     test_vehicle_id UUID;
-- BEGIN
--     -- Get a random vehicle ID for testing
--     SELECT vehicle_id INTO test_vehicle_id
--     FROM crm_vehicles
--     LIMIT 1;
--     
--     IF test_vehicle_id IS NOT NULL THEN
--         INSERT INTO mobile_activities (
--             vehicle_id,
--             vehicle_number,
--             activity_type,
--             user_name,
--             user_email,
--             timestamp,
--             metadata
--         ) VALUES (
--             test_vehicle_id,
--             'TEST-001',
--             'check_in',
--             'Test User',
--             'test@example.com',
--             NOW(),
--             '{"battery_percentage": 85, "charging_type": "AC"}'::jsonb
--         );
--         
--         RAISE NOTICE '✅ Test activity inserted successfully';
--         RAISE NOTICE '   You can delete this test record manually if needed';
--     ELSE
--         RAISE NOTICE '⚠️ No vehicles found for testing';
--     END IF;
-- END $$;

RAISE NOTICE '';
RAISE NOTICE '✅ ✅ ✅ RLS FIX COMPLETE! ✅ ✅ ✅';
RAISE NOTICE '';
RAISE NOTICE 'The mobile_activities table now allows:';
RAISE NOTICE '  ✅ Anonymous users to read activities';
RAISE NOTICE '  ✅ Anonymous users to insert activities';
RAISE NOTICE '  ✅ Authenticated users to read activities';
RAISE NOTICE '  ✅ Authenticated users to insert activities';
RAISE NOTICE '';
RAISE NOTICE 'Your Recent Activity section should now work!';

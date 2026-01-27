-- ============================================
-- Check and Fix Database Triggers
-- ============================================
-- This script checks for triggers that might reference
-- the old 'activities' table and removes them

-- Check for triggers on crm_vehicles table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'crm_vehicles'
ORDER BY trigger_name;

-- If you see any triggers that reference 'activities', 
-- drop them with:
-- DROP TRIGGER IF EXISTS trigger_name ON crm_vehicles;

-- Also check for functions that might reference activities
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_type = 'FUNCTION'
AND routine_definition LIKE '%activities%'
ORDER BY routine_name;

-- If you find any, you may need to drop and recreate them
-- to use 'mobile_activities' instead

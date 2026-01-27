-- ============================================
-- Quick Fix: Create View for Backward Compatibility
-- ============================================
-- This creates a view called 'activities' that points to 'mobile_activities'
-- This way, any code or triggers that reference 'activities' will still work

-- Drop the view if it exists
DROP VIEW IF EXISTS activities CASCADE;

-- Create a view that maps to mobile_activities
CREATE VIEW activities AS
SELECT 
    activity_id,
    vehicle_id,
    vehicle_number,
    activity_type,
    user_name,
    user_email,
    timestamp,
    metadata,
    created_at
FROM mobile_activities;

-- Allow inserts through the view
CREATE OR REPLACE RULE activities_insert AS
ON INSERT TO activities
DO INSTEAD
INSERT INTO mobile_activities (
    vehicle_id,
    vehicle_number,
    activity_type,
    user_name,
    user_email,
    timestamp,
    metadata,
    created_at
)
VALUES (
    NEW.vehicle_id,
    NEW.vehicle_number,
    NEW.activity_type,
    NEW.user_name,
    NEW.user_email,
    COALESCE(NEW.timestamp, NOW()),
    COALESCE(NEW.metadata, '{}'::jsonb),
    COALESCE(NEW.created_at, NOW())
)
RETURNING *;

-- Enable RLS on the view
ALTER VIEW activities SET (security_invoker = on);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Created view: activities → mobile_activities';
    RAISE NOTICE '   Old code referencing "activities" will now work!';
END $$;

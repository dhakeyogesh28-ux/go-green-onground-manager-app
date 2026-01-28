-- ============================================
-- FIX: Update Vehicle Status Change Trigger
-- ============================================
-- This fixes the trigger that logs vehicle status changes
-- The trigger was missing the required 'vehicle_number' field
-- Run this in your Supabase SQL Editor

-- Drop the old trigger and function
DROP TRIGGER IF EXISTS trg_vehicle_status_change ON crm_vehicles;
DROP FUNCTION IF EXISTS log_vehicle_status_change();

-- Create the fixed function that includes vehicle_number
-- SECURITY DEFINER allows the function to bypass RLS
CREATE OR REPLACE FUNCTION log_vehicle_status_change()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO mobile_activities (
            vehicle_id,
            vehicle_number,  -- THIS WAS MISSING!
            activity_type,
            user_email,
            metadata,
            created_at,
            timestamp
        ) VALUES (
            NEW.vehicle_id,
            COALESCE(NEW.registration_number, 'UNKNOWN'),  -- Use registration_number as vehicle_number
            'status_change',
            current_setting('request.jwt.claims', true)::json->>'email',  -- Try to get email from JWT
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
    WHEN (OLD.status IS DISTINCT FROM NEW.status)  -- Only fire when status actually changes
    EXECUTE FUNCTION log_vehicle_status_change();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Fixed vehicle status change trigger - now includes vehicle_number';
END $$;


-- Add mobile field to users table for profile editing
-- This migration adds a mobile/phone number field to the users table

-- Step 1: Add mobile column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'mobile'
    ) THEN
        ALTER TABLE users ADD COLUMN mobile VARCHAR(20);
        RAISE NOTICE 'Added mobile column to users table';
    ELSE
        RAISE NOTICE 'mobile column already exists in users table';
    END IF;
END $$;

-- Step 2: Create index on mobile for faster lookups (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile);

-- Step 3: Add comment to document the column
COMMENT ON COLUMN users.mobile IS 'User mobile/phone number for contact purposes';

-- Verification query - uncomment to check the schema
-- SELECT column_name, data_type, character_maximum_length 
-- FROM information_schema.columns 
-- WHERE table_name = 'users' AND column_name IN ('email', 'full_name', 'mobile', 'hub');

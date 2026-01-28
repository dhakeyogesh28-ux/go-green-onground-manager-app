# Database Migration Guide - Mobile App Fields

## Problem
The mobile app is trying to save data to columns that don't exist in the `crm_vehicles` table, causing this error:

```
PostgrestException: Could not find the 'battery_level' column of 'crm_vehicles' in the schema cache
```

## Solution
Run the database migration to add all required columns.

## Step-by-Step Instructions

### Option 1: Using Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com
   - Login to your project
   - Click on your project

2. **Navigate to SQL Editor**
   - In the left sidebar, click **SQL Editor**
   - Click **New Query**

3. **Copy and Paste the Migration**
   - Open the file: `database_migration_mobile_fields.sql`
   - Copy the entire contents
   - Paste into the SQL Editor

4. **Run the Migration**
   - Click **Run** button (or press Ctrl+Enter)
   - Wait for completion (should take a few seconds)
   - You should see: "Success. No rows returned"

5. **Verify the Migration**
   - Uncomment the verification queries at the bottom of the file
   - Run them to check if columns were added

### Option 2: Using Supabase CLI

If you have Supabase CLI installed:

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run the migration
supabase db push
```

### Option 3: Using psql (PostgreSQL Client)

If you have direct database access:

```bash
psql -h YOUR_DB_HOST -U YOUR_DB_USER -d YOUR_DB_NAME -f database_migration_mobile_fields.sql
```

## What This Migration Does

### Adds the Following Columns:

1. **Battery & Charging**
   - `battery_level` (INTEGER) - Current battery percentage (0-100)
   - `battery_health` (INTEGER) - Battery health percentage (0-100)
   - `last_charge_type` (TEXT) - Last charging type: AC or DC
   - `last_charging_type` (TEXT) - Alternate field for charging type

2. **Inspection & Inventory**
   - `daily_checks` (JSONB) - Inspection checklist results
   - `last_inventory_time` (TIMESTAMPTZ) - Last photo capture time
   - `last_inspection_date` (DATE) - Last inspection date
   - `inventory_photo_count` (INTEGER) - Number of photos captured

3. **Check-In/Out Tracking**
   - `is_vehicle_in` (BOOLEAN) - Whether vehicle is in hub
   - `last_check_in_time` (TIMESTAMPTZ) - Last check-in timestamp
   - `last_check_out_time` (TIMESTAMPTZ) - Last check-out timestamp

4. **DC Charging Limit**
   - `consecutive_dc_charges` (INTEGER) - Counter for DC charges (max 5)

5. **Service & Maintenance**
   - `last_service_date` (TIMESTAMPTZ) - Last service date
   - `last_service_type` (TEXT) - Type of last service
   - `service_attention` (BOOLEAN) - Needs attention flag
   - `charging_health` (TEXT) - Charging system health
   - `to_dos` (JSONB) - Pending tasks array

### Also Creates:

- ✅ Constraints for data integrity (battery 0-100, valid charge types)
- ✅ Indexes for better query performance
- ✅ Triggers for automatic timestamp updates
- ✅ RLS policies for authenticated users
- ✅ Comments documenting each column

## After Running the Migration

1. **Restart the Mobile App**
   - The app should now work without errors
   - Check-in/check-out data will be saved properly

2. **Test Check-Out**
   - Fill out a check-out form
   - You should see: `✅ Check-out completed successfully`
   - No more PostgrestException errors!

3. **Verify Data is Saved**
   - Go to Supabase Dashboard → Table Editor
   - Open `crm_vehicles` table
   - You should see the new columns with data

## Verification Queries

After running the migration, run these queries to verify:

```sql
-- Check if all columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'crm_vehicles' 
AND column_name IN (
    'battery_level', 'battery_health', 'last_charge_type', 
    'daily_checks', 'is_vehicle_in', 'consecutive_dc_charges'
)
ORDER BY column_name;

-- View sample data
SELECT 
    vehicle_id,
    registration_number,
    battery_level,
    last_charge_type,
    is_vehicle_in,
    status
FROM crm_vehicles
LIMIT 5;
```

## Troubleshooting

### Error: "column already exists"
- This is fine! It means some columns were already added
- The migration uses `IF NOT EXISTS` so it's safe to run multiple times

### Error: "permission denied"
- Make sure you're logged in as a user with database admin permissions
- In Supabase, use the service role key or run from the dashboard

### Error: "table crm_vehicles does not exist"
- Make sure you're connected to the correct database
- Check if the table name is different in your setup

## Important Notes

- ✅ **Safe to run multiple times** - Uses `IF NOT EXISTS` and `COALESCE`
- ✅ **Won't delete existing data** - Only adds new columns
- ✅ **Sets default values** - Existing records get sensible defaults
- ✅ **Backward compatible** - Won't break existing queries

## Next Steps

After running the migration:

1. ✅ Test check-in/check-out in the mobile app
2. ✅ Verify data persists after closing the app
3. ✅ Check that vehicle status updates correctly
4. ✅ Confirm battery level and charging type are saved

The mobile app should now work perfectly! 🎉

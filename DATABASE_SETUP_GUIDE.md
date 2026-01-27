# Complete Database Setup Guide for Mobile App

## Overview
This guide will help you set up all required database tables and columns for the mobile app to work properly.

## Prerequisites
- Access to Supabase Dashboard
- Admin/Owner permissions on the database
- Your Flutter mobile app project

## Setup Steps (15 minutes)

### Step 1: Create Mobile App Tables (REQUIRED)

This creates the tables for activities, maintenance jobs, and photos.

#### Open Supabase Dashboard
1. Go to https://supabase.com
2. Login and select your project
3. Click **SQL Editor** in the left sidebar
4. Click **New Query**

#### Run the Migration
1. Open file: `database_create_mobile_tables.sql`
2. Copy **ALL** contents (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor
4. Click **Run** (or Ctrl+Enter)
5. Wait for "Success" message

**This creates:**
- ✅ `mobile_activities` - Activity log
- ✅ `mobile_maintenance_jobs` - Maintenance jobs
- ✅ `mobile_inventory_photos` - Inventory photos
- ✅ `mobile_daily_inventory` - Daily checks

### Step 2: Add Mobile Fields to Vehicles Table (REQUIRED)

This adds battery, charging, and inspection fields to the vehicles table.

#### Run the Migration
1. In Supabase SQL Editor, click **New Query**
2. Open file: `database_migration_mobile_fields.sql`
3. Copy **ALL** contents
4. Paste into SQL Editor
5. Click **Run**

**This adds columns:**
- ✅ `battery_level` - Battery percentage
- ✅ `battery_health` - Battery health
- ✅ `last_charge_type` - AC/DC charging
- ✅ `daily_checks` - Inspection results
- ✅ `is_vehicle_in` - IN/OUT status
- ✅ `consecutive_dc_charges` - DC charge counter
- ✅ And more...

### Step 3: Fix Status Constraint (REQUIRED)

This allows the mobile app to set status to 'charging' and 'maintenance'.

#### Run the Fix
1. In Supabase SQL Editor, click **New Query**
2. Open file: `database_fix_status_constraint.sql`
3. Copy **ALL** contents
4. Paste into SQL Editor
5. Click **Run**

**This updates:**
- ✅ Status constraint to include: `'charging'`, `'maintenance'`, `'idle'`

### Step 4: Verify Setup

Run this verification query:

```sql
-- Check if all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'mobile_activities',
    'mobile_maintenance_jobs',
    'mobile_inventory_photos',
    'mobile_daily_inventory',
    'crm_vehicles'
)
ORDER BY table_name;

-- Should return 5 rows
```

### Step 5: Test the Mobile App

1. **Restart the mobile app** (hot reload won't work)
2. **Check-out a vehicle**:
   - Select vehicle
   - Fill battery: 85%
   - Select charging: AC
   - Mark 1 item as Issue
   - Take 2-3 photos
   - Click "Complete Check-Out"
3. **Watch for success message**: "Vehicle checked out successfully" ✅
4. **No errors should appear!**

### Step 6: Verify Data in Database

Run these queries to confirm data was saved:

```sql
-- Check recent activities
SELECT * FROM mobile_activities 
ORDER BY timestamp DESC 
LIMIT 5;

-- Check maintenance jobs
SELECT * FROM mobile_maintenance_jobs 
ORDER BY diagnosis_date DESC 
LIMIT 5;

-- Check vehicle data
SELECT 
    registration_number,
    battery_level,
    last_charge_type,
    status,
    is_vehicle_in
FROM crm_vehicles 
WHERE last_check_out_time IS NOT NULL
ORDER BY last_check_out_time DESC 
LIMIT 5;
```

## Complete Migration Order

Run these files in this exact order:

1. ✅ **`database_create_mobile_tables.sql`** - Creates activity/maintenance/photo tables
2. ✅ **`database_migration_mobile_fields.sql`** - Adds fields to vehicles table
3. ✅ **`database_fix_status_constraint.sql`** - Fixes status constraint
4. ✅ **`database_migration.sql`** - (Optional) Additional vehicle status setup

## What Each Migration Does

### Migration 1: Create Mobile Tables
**File**: `database_create_mobile_tables.sql`

Creates 4 new tables:

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `mobile_activities` | Activity log | activity_type, vehicle_id, metadata |
| `mobile_maintenance_jobs` | Maintenance jobs | issue_type, description, status |
| `mobile_inventory_photos` | Photos | photo_url, category, vehicle_id |
| `mobile_daily_inventory` | Daily checks | check_date, notes, status |

**Also creates:**
- Indexes for performance
- Foreign keys to `crm_vehicles`
- RLS policies for security
- Triggers for timestamps

### Migration 2: Add Mobile Fields
**File**: `database_migration_mobile_fields.sql`

Adds 15+ columns to `crm_vehicles`:

| Column | Type | Purpose |
|--------|------|---------|
| `battery_level` | INTEGER | Battery % (0-100) |
| `battery_health` | INTEGER | Battery health % |
| `last_charge_type` | TEXT | AC or DC |
| `daily_checks` | JSONB | Inspection results |
| `is_vehicle_in` | BOOLEAN | IN/OUT status |
| `consecutive_dc_charges` | INTEGER | DC counter (0-5) |
| `last_inventory_time` | TIMESTAMPTZ | Photo timestamp |
| `last_inspection_date` | DATE | Inspection date |
| `service_attention` | BOOLEAN | Needs attention |
| ... and more | | |

**Also creates:**
- Constraints (battery 0-100, valid charge types)
- Indexes for queries
- Triggers for timestamps
- Comments for documentation

### Migration 3: Fix Status Constraint
**File**: `database_fix_status_constraint.sql`

Updates the status CHECK constraint:

**Before:**
```sql
CHECK (status IN ('active', 'inactive', 'scrapped', 'trial'))
```

**After:**
```sql
CHECK (status IN (
    'active',       -- Checked out
    'inactive',     -- Not in use
    'scrapped',     -- Decommissioned
    'trial',        -- Testing
    'charging',     -- ← NEW: Checked in
    'maintenance',  -- ← NEW: Needs service
    'idle'          -- ← NEW: Available
))
```

## Troubleshooting

### Error: "relation already exists"
**Solution**: Table already created. Skip to next migration. ✅

### Error: "column already exists"
**Solution**: Column already added. Skip to next migration. ✅

### Error: "constraint already exists"
**Solution**: Constraint already updated. You're good! ✅

### Error: "permission denied"
**Solution**: 
- Make sure you're logged in as database admin
- Use Supabase dashboard (has admin permissions)

### Error: "foreign key violation"
**Solution**: 
- Make sure `crm_vehicles` table exists first
- Check that `vehicle_id` column exists in `crm_vehicles`

### Mobile app still shows errors
**Solution**:
1. Verify all 3 migrations ran successfully
2. Restart the mobile app (stop and run again)
3. Check console for specific error messages
4. Run verification queries to confirm tables exist

## Verification Checklist

After running all migrations, verify:

- [ ] `mobile_activities` table exists
- [ ] `mobile_maintenance_jobs` table exists
- [ ] `mobile_inventory_photos` table exists
- [ ] `mobile_daily_inventory` table exists
- [ ] `crm_vehicles` has `battery_level` column
- [ ] `crm_vehicles` has `daily_checks` column
- [ ] `crm_vehicles` has `is_vehicle_in` column
- [ ] Status constraint includes 'charging' and 'maintenance'
- [ ] Mobile app check-out works without errors
- [ ] Data appears in database after check-out

## Quick Verification Query

Run this to check everything:

```sql
-- Check tables
SELECT 'Tables' as check_type, COUNT(*) as count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'mobile_%'

UNION ALL

-- Check vehicle columns
SELECT 'Vehicle Columns' as check_type, COUNT(*) as count
FROM information_schema.columns
WHERE table_name = 'crm_vehicles' 
AND column_name IN ('battery_level', 'daily_checks', 'is_vehicle_in')

UNION ALL

-- Check status constraint
SELECT 'Status Constraint' as check_type, 
       CASE WHEN check_clause LIKE '%charging%' THEN 1 ELSE 0 END as count
FROM information_schema.check_constraints
WHERE constraint_name = 'crm_vehicles_status_check';

-- Expected results:
-- Tables: 4
-- Vehicle Columns: 3
-- Status Constraint: 1
```

## After Setup

Once all migrations are complete:

✅ **Mobile app will work** - No more database errors  
✅ **Check-in/out will save** - All data persists  
✅ **Issues will be reported** - Maintenance jobs created  
✅ **Photos will be uploaded** - Stored in Supabase  
✅ **Activities will be logged** - Complete audit trail  
✅ **Admin panel can access** - All data available  

## Summary

**3 Required Migrations:**
1. Create mobile tables (activities, jobs, photos)
2. Add mobile fields to vehicles table
3. Fix status constraint

**Total Time:** ~15 minutes  
**Difficulty:** Easy (just copy & paste SQL)  
**Risk:** None (safe operations, won't delete data)  

Run all 3 migrations and your mobile app will work perfectly! 🎉

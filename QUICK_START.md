# ✅ Quick Start Checklist - Mobile App Setup

## The Error You're Seeing

```
Error: relation "activities" does not exist
```

**This means**: The database tables haven't been created yet.

## Fix It in 3 Steps (15 minutes)

### ☐ Step 1: Create Mobile Tables

**What**: Creates tables for activities, maintenance jobs, and photos

**How**:
1. Open Supabase Dashboard → SQL Editor
2. Open file: `database_create_mobile_tables.sql`
3. Copy ALL contents
4. Paste into SQL Editor
5. Click **Run**
6. Wait for "Success"

**Creates**: `mobile_activities`, `mobile_maintenance_jobs`, `mobile_inventory_photos`, `mobile_daily_inventory`

---

### ☐ Step 2: Add Mobile Fields to Vehicles

**What**: Adds battery, charging, inspection fields to vehicles table

**How**:
1. In SQL Editor, click **New Query**
2. Open file: `database_migration_mobile_fields.sql`
3. Copy ALL contents
4. Paste into SQL Editor
5. Click **Run**
6. Wait for "Success"

**Adds**: `battery_level`, `daily_checks`, `is_vehicle_in`, and 12+ more columns

---

### ☐ Step 3: Fix Status Constraint

**What**: Allows status to be 'charging' and 'maintenance'

**How**:
1. In SQL Editor, click **New Query**
2. Open file: `database_fix_status_constraint.sql`
3. Copy ALL contents
4. Paste into SQL Editor
5. Click **Run**
6. Wait for "Success"

**Fixes**: Status constraint to include all mobile app statuses

---

### ☐ Step 4: Test the Mobile App

**What**: Verify everything works

**How**:
1. **Restart** the mobile app (stop and run again)
2. Go to **Check-Out** screen
3. Select a vehicle
4. Fill the form:
   - Battery: 85%
   - Charging: AC
   - Mark 1 item as "Issue"
   - Take 2-3 photos
5. Click **"Complete Check-Out"**
6. Watch for: ✅ "Vehicle checked out successfully"

**Expected**: No errors! Data saved to database.

---

### ☐ Step 5: Verify Data Saved

**What**: Confirm data is in database

**How**:
1. In Supabase, go to **Table Editor**
2. Open **`mobile_activities`** table
3. Should see your check-out activity
4. Open **`crm_vehicles`** table
5. Find your vehicle
6. Check `battery_level` = 85 ✅

**Expected**: All data visible in database

---

## That's It!

After these 5 steps:
- ✅ No more database errors
- ✅ Check-in/out works perfectly
- ✅ Data persists after closing app
- ✅ Issues reported to admin automatically
- ✅ Photos uploaded to storage
- ✅ Complete activity tracking

## Quick Reference

### Files to Run (in order):
1. `database_create_mobile_tables.sql`
2. `database_migration_mobile_fields.sql`
3. `database_fix_status_constraint.sql`

### Where to Run:
- Supabase Dashboard → SQL Editor

### How Long:
- ~15 minutes total

### Difficulty:
- Easy (just copy & paste)

### Risk:
- None (won't delete data)

## Verification Query

After running all migrations, run this to verify:

```sql
-- Should return 4 tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'mobile_%';

-- Should return 3 columns
SELECT column_name 
FROM information_schema.columns
WHERE table_name = 'crm_vehicles' 
AND column_name IN ('battery_level', 'daily_checks', 'is_vehicle_in');

-- Should include 'charging' in the constraint
SELECT check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'crm_vehicles_status_check';
```

## Need Help?

### Error: "relation already exists"
✅ **Good!** Table already created. Skip to next step.

### Error: "column already exists"
✅ **Good!** Column already added. Skip to next step.

### Error: "permission denied"
❌ **Fix**: Make sure you're logged in as database admin in Supabase.

### Mobile app still shows errors
❌ **Fix**: 
1. Verify all 3 migrations ran successfully
2. Restart the mobile app completely
3. Check console for specific error

## Documentation

For detailed information, see:
- **`DATABASE_SETUP_GUIDE.md`** - Complete setup guide
- **`IMPLEMENTATION_SUMMARY.md`** - What was built
- **`VERIFY_DATA_STORAGE.md`** - How to verify data

## Summary

**Problem**: Database missing tables/columns  
**Solution**: Run 3 SQL migration scripts  
**Time**: 15 minutes  
**Result**: Fully working mobile app! 🎉

---

**Start with Step 1 and work your way down. You'll be done in 15 minutes!**

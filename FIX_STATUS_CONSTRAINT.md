# Fixing Status Constraint Error - Quick Guide

## The Error

```
PostgrestException: Failing row contains (..., maintenance, ...)
"hint":"message":"Failing row for relation \"crm_vehicles\" violates check constraint \"crm_vehicles_status_check\""
```

## What This Means

The `crm_vehicles` table has a CHECK constraint that only allows these status values:
- ❌ `'active'`
- ❌ `'inactive'`
- ❌ `'scrapped'`
- ❌ `'trial'`

But the mobile app is trying to set the status to:
- ⚠️ `'charging'` (when checking in)
- ⚠️ `'maintenance'` (when issues are found)
- ⚠️ `'idle'` (for available vehicles)

These values are **not allowed** by the current constraint, causing the error.

## The Solution

Update the constraint to include all status values used by the mobile app.

### Quick Fix (5 minutes)

#### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com
2. Login and open your project
3. Click **SQL Editor** in the left sidebar
4. Click **New Query**

#### Step 2: Run the Fix Script
Copy and paste this SQL:

```sql
-- Drop the old constraint
ALTER TABLE crm_vehicles
DROP CONSTRAINT IF EXISTS crm_vehicles_status_check;

-- Add new constraint with all status values
ALTER TABLE crm_vehicles
ADD CONSTRAINT crm_vehicles_status_check 
CHECK (status IN (
    'active',       -- Vehicle checked out / in use
    'inactive',     -- Not in use
    'scrapped',     -- Decommissioned
    'trial',        -- Testing phase
    'charging',     -- Checked in and charging (Mobile App)
    'maintenance',  -- Needs service/repair (Mobile App)
    'idle'          -- Available but not in use (Mobile App)
));
```

#### Step 3: Click Run
- Click the **Run** button (or press Ctrl+Enter)
- You should see: "Success. No rows returned"

#### Step 4: Test the Mobile App
- Try checking out a vehicle
- Should work without errors now! ✅

## Alternative: Use the Quick Fix File

I've created a file: `database_fix_status_constraint.sql`

1. Open the file
2. Copy all contents
3. Paste into Supabase SQL Editor
4. Run it

## What Each Status Means

| Status | When Used | Set By |
|--------|-----------|--------|
| `active` | Vehicle checked out and in use | Mobile App (check-out) |
| `inactive` | Vehicle not in use | Admin Panel |
| `scrapped` | Vehicle decommissioned | Admin Panel |
| `trial` | Vehicle in testing phase | Admin Panel |
| `charging` | Vehicle checked in and charging | Mobile App (check-in) |
| `maintenance` | Vehicle needs service/repair | Mobile App (when issues found) |
| `idle` | Vehicle available but not in use | Mobile App / Admin Panel |

## How the Mobile App Uses Status

### Check-In Flow:
```
User checks in vehicle
  ↓
Has issues? 
  → YES: status = 'maintenance'
  → NO:  status = 'charging'
```

### Check-Out Flow:
```
User checks out vehicle
  ↓
Has issues?
  → YES: status = 'maintenance'
  → NO:  status = 'active'
```

## Verification

After running the fix, verify it worked:

```sql
-- Check the constraint
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'crm_vehicles_status_check';

-- Should show: status IN ('active', 'inactive', 'scrapped', 'trial', 'charging', 'maintenance', 'idle')
```

## Test the Fix

Try updating a vehicle status:

```sql
-- Test: Set status to 'charging' (should work now)
UPDATE crm_vehicles 
SET status = 'charging' 
WHERE vehicle_id = (SELECT vehicle_id FROM crm_vehicles LIMIT 1);

-- Test: Set status to 'maintenance' (should work now)
UPDATE crm_vehicles 
SET status = 'maintenance' 
WHERE vehicle_id = (SELECT vehicle_id FROM crm_vehicles LIMIT 1);
```

If both work without errors, the fix is successful! ✅

## After Fixing

1. ✅ Check-in will work (sets status to 'charging')
2. ✅ Check-out will work (sets status to 'active')
3. ✅ Issue reporting will work (sets status to 'maintenance')
4. ✅ No more constraint violation errors

## Important Notes

- ✅ **Safe to run** - Only updates the constraint, doesn't change data
- ✅ **No downtime** - Can run while app is running
- ✅ **Backward compatible** - Admin panel still works with old statuses
- ✅ **One-time fix** - Only needs to be run once

## If You Still Get Errors

### Error: "constraint does not exist"
- This is fine! It means the constraint wasn't created yet
- The script will still create the new constraint

### Error: "permission denied"
- Make sure you're logged in as database admin
- Use the Supabase dashboard (has admin permissions)

### Error: "syntax error"
- Make sure you copied the entire SQL script
- Check for any missing parentheses or quotes

## Summary

**Problem**: Status constraint too restrictive  
**Solution**: Update constraint to include mobile app statuses  
**Time**: 5 minutes  
**Risk**: None (safe operation)  
**Result**: Mobile app check-in/out works perfectly ✅  

Run the fix script and your mobile app will work! 🎉

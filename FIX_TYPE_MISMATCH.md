# Database Type Mismatch - FIXED

## The Error

```
ERROR: foreign key constraint "fk_mobile_activities_vehicle" cannot be implemented
DETAIL: Key columns "vehicle_id" and "vehicle_id" are of incompatible types: text and uuid.
```

## What This Meant

The `crm_vehicles` table has `vehicle_id` as **UUID** type, but the mobile tables were defined with `vehicle_id` as **TEXT** type. This caused a type mismatch when trying to create foreign key constraints.

## The Fix

Changed `vehicle_id` from `TEXT` to `UUID` in all mobile tables:

### Tables Fixed:
1. ✅ `mobile_activities` - vehicle_id now UUID
2. ✅ `mobile_maintenance_jobs` - vehicle_id now UUID
3. ✅ `mobile_inventory_photos` - vehicle_id now UUID
4. ✅ `mobile_daily_inventory` - vehicle_id now UUID

### File Updated:
- ✅ `database_create_mobile_tables.sql`

## Now You Can Run It

The migration script is now fixed and ready to run:

1. Open Supabase Dashboard → SQL Editor
2. Open file: `database_create_mobile_tables.sql`
3. Copy ALL contents
4. Paste into SQL Editor
5. Click **Run**
6. Should work without errors! ✅

## What Changed

**Before:**
```sql
CREATE TABLE mobile_activities (
    vehicle_id TEXT NOT NULL,  -- ❌ Wrong type
    ...
);
```

**After:**
```sql
CREATE TABLE mobile_activities (
    vehicle_id UUID NOT NULL,  -- ✅ Correct type
    ...
);
```

## Verification

After running the migration, verify with:

```sql
-- Check column types
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name LIKE 'mobile_%'
AND column_name = 'vehicle_id'
ORDER BY table_name;

-- Should show all as 'uuid'
```

## Summary

**Problem**: Type mismatch (TEXT vs UUID)  
**Solution**: Changed all vehicle_id columns to UUID  
**Status**: ✅ FIXED  
**Next Step**: Run the migration script  

The script is now ready to use! 🎉

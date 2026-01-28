# Quick Setup Guide - Driver Assignment

## ✅ Fixed Migration Issue

**Problem:** The original migration referenced a `hubs` table that doesn't exist.

**Solution:** Updated the migration to remove the foreign key constraint on `hub_id`, making it a simple UUID field.

## 🚀 Quick Setup (3 Steps)

### Step 1: Run the Quick Setup Script

1. Open your **Supabase Dashboard**
2. Go to **SQL Editor**
3. Copy and paste the contents of **`database_driver_quick_setup.sql`**
4. Click **Run**

This will create:
- ✅ `drivers` table
- ✅ `driver_attendance` table
- ✅ Indexes for performance
- ✅ RLS policies for security

### Step 2: Add Sample Drivers

Run this SQL to add test drivers:

```sql
INSERT INTO drivers (driver_name, phone_number, email, license_number, is_active)
VALUES 
    ('Rajesh Kumar', '+91 9876543210', 'rajesh@example.com', 'MH12-20230001', true),
    ('Amit Sharma', '+91 9876543211', 'amit@example.com', 'MH12-20230002', true),
    ('Priya Patel', '+91 9876543212', 'priya@example.com', 'MH12-20230003', true),
    ('Suresh Reddy', '+91 9876543213', 'suresh@example.com', 'MH12-20230004', true),
    ('Vikram Singh', '+91 9876543214', 'vikram@example.com', 'MH12-20230005', true);
```

### Step 3: Verify Setup

Check if everything is working:

```sql
-- View all drivers
SELECT driver_id, driver_name, phone_number, license_number, is_active
FROM drivers
ORDER BY driver_name;

-- Check table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'drivers'
ORDER BY ordinal_position;
```

## 📱 Test in the App

1. **Open the app** (flutter run should be running)
2. **Navigate to Check-In** screen
3. **Select a vehicle**
4. **See the "Assigned Driver" section**
5. **Search for a driver** (try typing "rajesh" or "9876543210")
6. **Select a driver** from the results
7. **Complete check-in**
8. **Verify attendance** was recorded:

```sql
SELECT 
    da.timestamp,
    da.activity_type,
    d.driver_name,
    da.metadata
FROM driver_attendance da
JOIN drivers d ON da.driver_id = d.driver_id
ORDER BY da.timestamp DESC
LIMIT 5;
```

## 🔧 Troubleshooting

### Issue: "relation 'hubs' does not exist"
**Solution:** Use the updated migration files:
- ✅ `database_driver_migration.sql` (updated - no FK constraint)
- ✅ `database_driver_quick_setup.sql` (new - simplified version)

### Issue: "relation 'crm_vehicles' does not exist"
**Solution:** The `driver_attendance` table references `crm_vehicles`. Make sure your vehicles table exists. If it has a different name, update line 25 in the migration:

```sql
-- Change this line if your vehicles table has a different name
vehicle_id UUID NOT NULL REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE,
```

### Issue: Drivers not showing in search
**Check:**
1. Drivers exist: `SELECT COUNT(*) FROM drivers WHERE is_active = true;`
2. RLS policies are set: `SELECT * FROM pg_policies WHERE tablename = 'drivers';`
3. Check console logs in the app for errors

### Issue: Attendance not recording
**Check:**
1. Table exists: `SELECT * FROM driver_attendance LIMIT 1;`
2. RLS policies allow INSERT: `SELECT * FROM pg_policies WHERE tablename = 'driver_attendance';`
3. Check app console for error messages

## 📊 Useful Queries

### Today's Driver Activities
```sql
SELECT 
    d.driver_name,
    da.activity_type,
    da.timestamp,
    da.metadata->>'vehicle_number' as vehicle
FROM driver_attendance da
JOIN drivers d ON da.driver_id = d.driver_id
WHERE DATE(da.timestamp) = CURRENT_DATE
ORDER BY da.timestamp DESC;
```

### Driver Activity Summary
```sql
SELECT 
    d.driver_name,
    COUNT(*) FILTER (WHERE da.activity_type = 'check_in') as check_ins,
    COUNT(*) FILTER (WHERE da.activity_type = 'check_out') as check_outs,
    MAX(da.timestamp) as last_activity
FROM drivers d
LEFT JOIN driver_attendance da ON d.driver_id = da.driver_id
WHERE d.is_active = true
GROUP BY d.driver_id, d.driver_name
ORDER BY last_activity DESC NULLS LAST;
```

### Add a New Driver
```sql
INSERT INTO drivers (driver_name, phone_number, license_number, is_active)
VALUES ('New Driver Name', '+91 9999999999', 'LICENSE123', true);
```

### Deactivate a Driver
```sql
UPDATE drivers 
SET is_active = false 
WHERE driver_name = 'Driver Name';
```

## ✨ What's Different in the Updated Migration

**Before (❌ Error):**
```sql
hub_id UUID REFERENCES hubs(hub_id) ON DELETE SET NULL,
```

**After (✅ Fixed):**
```sql
hub_id UUID,  -- No foreign key constraint
```

This allows the driver management to work independently without requiring a `hubs` table. You can still store hub IDs, but there's no database-level constraint.

## 📝 Files to Use

1. **`database_driver_quick_setup.sql`** ⭐ **Use this one!** - Simplified, ready to run
2. **`database_driver_migration.sql`** - Full version with all features (also fixed)

Both files are now updated and will work without the `hubs` table.

---

**Status:** ✅ Ready to use!  
**Next Step:** Run `database_driver_quick_setup.sql` in Supabase SQL Editor

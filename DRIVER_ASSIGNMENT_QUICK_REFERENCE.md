# Driver Assignment - Quick Reference Guide

## 🚀 Quick Start

### 1. Database Setup (One-time)
```sql
-- Run this in Supabase SQL Editor
-- Copy contents from: database_driver_migration.sql
```

### 2. Add Sample Drivers
```sql
INSERT INTO drivers (driver_name, phone_number, email, license_number, is_active)
VALUES 
    ('Rajesh Kumar', '+91 9876543210', 'rajesh@example.com', 'MH12-20230001', true),
    ('Amit Sharma', '+91 9876543211', 'amit@example.com', 'MH12-20230002', true);
```

### 3. Test in App
1. Open Check-In screen
2. Select a vehicle
3. See "Assigned Driver" section
4. Search and select a driver
5. Complete check-in

## 📱 User Flow

```
Select Vehicle → Driver Assignment Section Appears
                 ↓
    ┌────────────┴────────────┐
    ↓                         ↓
Auto-load Last Driver    Search New Driver
    ↓                         ↓
    └────────────┬────────────┘
                 ↓
         Selected Driver Card
                 ↓
      Complete Check-in/Check-out
                 ↓
    ┌────────────┴────────────┐
    ↓                         ↓
Mark Attendance          Log Activity
```

## 🔍 Search Examples

| Search Term | Matches |
|-------------|---------|
| `rajesh` | Driver name containing "rajesh" |
| `9876543210` | Phone number |
| `MH12-2023` | License number |

## 💾 Database Queries

### View All Drivers
```sql
SELECT driver_id, driver_name, phone_number, license_number, is_active
FROM drivers
WHERE is_active = true
ORDER BY driver_name;
```

### View Recent Attendance
```sql
SELECT 
    da.timestamp,
    da.activity_type,
    d.driver_name,
    v.registration_number as vehicle,
    da.metadata->>'battery_percentage' as battery
FROM driver_attendance da
JOIN drivers d ON da.driver_id = d.driver_id
JOIN crm_vehicles v ON da.vehicle_id = v.vehicle_id
ORDER BY da.timestamp DESC
LIMIT 20;
```

### Driver Attendance Summary
```sql
SELECT 
    d.driver_name,
    COUNT(*) FILTER (WHERE da.activity_type = 'check_in') as check_ins,
    COUNT(*) FILTER (WHERE da.activity_type = 'check_out') as check_outs,
    COUNT(*) as total_activities
FROM drivers d
LEFT JOIN driver_attendance da ON d.driver_id = da.driver_id
WHERE d.is_active = true
GROUP BY d.driver_id, d.driver_name
ORDER BY total_activities DESC;
```

### Today's Driver Activities
```sql
SELECT 
    d.driver_name,
    da.activity_type,
    v.registration_number,
    da.timestamp
FROM driver_attendance da
JOIN drivers d ON da.driver_id = d.driver_id
JOIN crm_vehicles v ON da.vehicle_id = v.vehicle_id
WHERE DATE(da.timestamp) = CURRENT_DATE
ORDER BY da.timestamp DESC;
```

## 🎨 UI Components

### Driver Assignment Section Widget
```dart
DriverAssignmentSection(
  vehicleId: vehicle.id,      // Current vehicle
  hubId: userHub,              // Filter by hub
  onDriverSelected: (driver) { // Callback
    setState(() {
      _selectedDriver = driver;
    });
  },
)
```

### Search Features
- ✅ Real-time search as you type
- ✅ Search by name, phone, or license
- ✅ Hub-based filtering
- ✅ Auto-load last assigned driver
- ✅ Clear selection option

## 🔧 Troubleshooting

### Driver search returns no results
```sql
-- Check if drivers exist
SELECT COUNT(*) FROM drivers WHERE is_active = true;

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'drivers';
```

### Attendance not recording
```sql
-- Check table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'driver_attendance'
);

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'driver_attendance';
```

### Last driver not loading
```sql
-- Check if attendance records exist for vehicle
SELECT * FROM driver_attendance 
WHERE vehicle_id = 'your-vehicle-id'
ORDER BY timestamp DESC
LIMIT 5;
```

## 📊 Analytics Queries

### Most Active Drivers (This Month)
```sql
SELECT 
    d.driver_name,
    COUNT(*) as activities,
    COUNT(DISTINCT da.vehicle_id) as unique_vehicles
FROM driver_attendance da
JOIN drivers d ON da.driver_id = d.driver_id
WHERE da.timestamp >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY d.driver_id, d.driver_name
ORDER BY activities DESC
LIMIT 10;
```

### Vehicle-Driver Assignments
```sql
SELECT 
    v.registration_number,
    d.driver_name,
    COUNT(*) as times_assigned,
    MAX(da.timestamp) as last_assignment
FROM driver_attendance da
JOIN drivers d ON da.driver_id = d.driver_id
JOIN crm_vehicles v ON da.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_id, v.registration_number, d.driver_id, d.driver_name
ORDER BY times_assigned DESC;
```

## 🔐 Security Checklist

- ✅ RLS enabled on `drivers` table
- ✅ RLS enabled on `driver_attendance` table
- ✅ Authenticated users only
- ✅ Proper foreign key constraints
- ✅ Check constraints on activity_type
- ✅ Cascading deletes configured

## 📝 Code Snippets

### Mark Attendance Manually
```dart
await DriverService.markAttendance(
  driverId: driver.id,
  vehicleId: vehicle.id,
  activityType: 'check_in',
  notes: 'Optional notes',
  metadata: {
    'vehicle_number': vehicle.vehicleNumber,
    'battery_level': 85,
  },
);
```

### Search Drivers
```dart
final drivers = await DriverService.searchDrivers(
  'rajesh',
  hubId: currentHubId,
);
```

### Get Driver Attendance
```dart
final attendance = await DriverService.getDriverAttendance(
  driverId: driver.id,
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
```

## 📈 Performance Tips

1. **Indexes** - Already created on:
   - driver_name
   - phone_number
   - license_number
   - hub_id
   - timestamp

2. **Query Optimization**
   - Use hub filtering to reduce result set
   - Limit search results (default: 20)
   - Use indexes for date range queries

3. **Caching**
   - Last assigned driver is cached
   - Search results are cached during session

## 🎯 Best Practices

1. **Always assign a driver** when checking in/out
2. **Verify driver details** before selection
3. **Use hub filtering** for better performance
4. **Check attendance records** regularly
5. **Keep driver data updated** in database

## 📞 Support

For issues or questions:
1. Check `DRIVER_ASSIGNMENT_README.md` for detailed docs
2. Review console logs for errors
3. Verify database migration completed
4. Check Supabase dashboard for RLS policies

---

**Quick Links:**
- Full Documentation: `DRIVER_ASSIGNMENT_README.md`
- Implementation Summary: `DRIVER_ASSIGNMENT_SUMMARY.md`
- Database Migration: `database_driver_migration.sql`

# Driver Assignment Feature

## Overview
The driver assignment feature allows users to search for and assign drivers to vehicles during check-in and check-out processes. Driver attendance is automatically tracked in the database.

## Features

### 1. Driver Search
- **Real-time search** by driver name, phone number, or license number
- **Hub-based filtering** - only shows drivers assigned to the current hub
- **Autocomplete suggestions** as you type

### 2. Driver Selection
- Select a driver from search results
- View driver details (name, phone, license number)
- Clear/change driver selection
- Automatically loads the last assigned driver for the vehicle

### 3. Attendance Tracking
- Automatically marks driver attendance on check-in
- Automatically marks driver attendance on check-out
- Stores metadata including vehicle number, driver name, and battery percentage
- Links attendance records to activities for audit trail

## Database Schema

### Drivers Table
```sql
drivers (
    driver_id UUID PRIMARY KEY,
    driver_name TEXT NOT NULL,
    phone_number TEXT,
    email TEXT,
    license_number TEXT,
    hub_id UUID REFERENCES hubs(hub_id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

### Driver Attendance Table
```sql
driver_attendance (
    attendance_id UUID PRIMARY KEY,
    driver_id UUID REFERENCES drivers(driver_id),
    vehicle_id UUID REFERENCES crm_vehicles(vehicle_id),
    activity_type TEXT CHECK (activity_type IN ('check_in', 'check_out')),
    timestamp TIMESTAMP,
    notes TEXT,
    metadata JSONB,
    created_at TIMESTAMP
)
```

## Setup Instructions

### 1. Run Database Migration
Execute the SQL migration file to create the necessary tables:

```bash
# Connect to your Supabase database and run:
psql -h your-supabase-host -U postgres -d postgres -f database_driver_migration.sql
```

Or use the Supabase SQL Editor:
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `database_driver_migration.sql`
4. Click "Run"

### 2. Add Sample Drivers (Optional)
Uncomment the sample data section in the migration file to add test drivers, or add drivers manually:

```sql
INSERT INTO drivers (driver_name, phone_number, email, license_number, is_active)
VALUES 
    ('John Doe', '+91 9876543210', 'john@example.com', 'MH12-20230001', true);
```

### 3. Configure RLS Policies
The migration automatically sets up Row Level Security (RLS) policies. Ensure your Supabase authentication is properly configured.

## Usage

### In Check-In Screen
1. Select a vehicle
2. The "Assigned Driver" section appears
3. Search for a driver by name, phone, or license
4. Select the driver from search results
5. Complete the check-in process
6. Driver attendance is automatically recorded

### In Check-Out Screen
1. Select a vehicle
2. The "Assigned Driver" section appears with the last assigned driver pre-loaded
3. You can change the driver if needed
4. Complete the check-out process
5. Driver attendance is automatically recorded

## API Reference

### DriverService Methods

#### `searchDrivers(query, {hubId})`
Search for drivers by name, phone, or license number.
- **Parameters:**
  - `query` (String): Search term
  - `hubId` (String, optional): Filter by hub
- **Returns:** `Future<List<Driver>>`

#### `getDriversByHub(hubId)`
Get all active drivers for a specific hub.
- **Parameters:**
  - `hubId` (String): Hub identifier
- **Returns:** `Future<List<Driver>>`

#### `getDriverById(driverId)`
Get a specific driver by ID.
- **Parameters:**
  - `driverId` (String): Driver identifier
- **Returns:** `Future<Driver?>`

#### `markAttendance({driverId, vehicleId, activityType, notes, metadata})`
Mark driver attendance for check-in or check-out.
- **Parameters:**
  - `driverId` (String): Driver identifier
  - `vehicleId` (String): Vehicle identifier
  - `activityType` (String): 'check_in' or 'check_out'
  - `notes` (String, optional): Additional notes
  - `metadata` (Map, optional): Additional metadata
- **Returns:** `Future<DriverAttendance?>`

#### `getDriverAttendance({driverId, vehicleId, startDate, endDate})`
Get driver attendance history with optional filters.
- **Parameters:**
  - `driverId` (String, optional): Filter by driver
  - `vehicleId` (String, optional): Filter by vehicle
  - `startDate` (DateTime, optional): Start date filter
  - `endDate` (DateTime, optional): End date filter
- **Returns:** `Future<List<DriverAttendance>>`

#### `getLastAssignedDriver(vehicleId)`
Get the last driver assigned to a vehicle.
- **Parameters:**
  - `vehicleId` (String): Vehicle identifier
- **Returns:** `Future<Driver?>`

## Widget Reference

### DriverAssignmentSection
A reusable widget for driver search and selection.

**Properties:**
- `vehicleId` (String?): Current vehicle ID
- `hubId` (String?): Current hub ID for filtering
- `onDriverSelected` (Function(Driver?)): Callback when driver is selected/cleared
- `initialDriver` (Driver?): Pre-selected driver

**Example:**
```dart
DriverAssignmentSection(
  vehicleId: vehicle.id,
  hubId: userHub,
  onDriverSelected: (driver) {
    setState(() {
      _selectedDriver = driver;
    });
  },
)
```

## Files Created/Modified

### New Files
- `lib/models/driver.dart` - Driver model
- `lib/models/driver_attendance.dart` - Driver attendance model
- `lib/services/driver_service.dart` - Driver service for database operations
- `lib/widgets/driver_assignment_section.dart` - Reusable driver assignment widget
- `database_driver_migration.sql` - Database migration script
- `DRIVER_ASSIGNMENT_README.md` - This documentation

### Modified Files
- `lib/screens/check_in_screen.dart` - Added driver assignment section
- `lib/screens/check_out_screen.dart` - Added driver assignment section

## Troubleshooting

### Driver search returns no results
- Verify the `drivers` table has data
- Check that drivers have `is_active = true`
- Ensure the hub_id matches if filtering by hub
- Check RLS policies are properly configured

### Attendance not being recorded
- Check database connection
- Verify `driver_attendance` table exists
- Check RLS policies allow INSERT operations
- Review console logs for error messages

### Last assigned driver not loading
- Ensure previous check-ins/check-outs recorded driver attendance
- Verify the vehicle_id is correct
- Check that the driver still exists and is active

## Future Enhancements
- Driver photo upload
- Driver shift management
- Driver performance metrics
- Driver availability calendar
- Multi-driver assignment for larger vehicles
- Driver notification system
- Driver rating system

## Support
For issues or questions, please refer to the main project documentation or contact the development team.

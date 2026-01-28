# Check-In/Check-Out Data Storage & Admin Panel Visibility

## Overview
All data filled in the check-in and check-out forms is automatically saved to the Supabase database and is visible in the admin panel.

## What Data is Saved

### 1. Vehicle Information Updates (`crm_vehicles` table)

When a user completes check-in or check-out, these fields are updated:

| Field | Description | Example Value | Admin Panel Location |
|-------|-------------|---------------|---------------------|
| `is_vehicle_in` | Whether vehicle is in hub | `true` / `false` | Vehicle Details |
| `status` | Current vehicle status | `'charging'`, `'active'`, `'maintenance'` | Vehicle Card, Kanban Board |
| `battery_level` | Battery percentage | `85` | Vehicle Details |
| `battery_health` | Battery health percentage | `85` | Vehicle Details |
| `last_charge_type` | Type of charging used | `'AC'` / `'DC'` | Vehicle Details |
| `last_charging_type` | Alternate charging field | `'AC'` / `'DC'` | Vehicle Details |
| `daily_checks` | Inspection checklist results | `{"battery_health": true, "charging_port": false}` | Vehicle Details (JSON) |
| `last_inventory_time` | When photos were taken | `2026-01-13T23:52:10Z` | Vehicle Details |
| `last_inspection_date` | Date of last inspection | `2026-01-13` | Vehicle Details |
| `inventory_photo_count` | Number of photos captured | `9` | Vehicle Details |
| `service_attention` | Needs attention flag | `true` / `false` | Vehicle Card (Alert Badge) |
| `consecutive_dc_charges` | DC charge counter | `0-5` | Vehicle Details |
| `last_check_in_time` | Last check-in timestamp | `2026-01-13T23:52:10Z` | Vehicle Timeline |
| `last_check_out_time` | Last check-out timestamp | `2026-01-13T23:52:10Z` | Vehicle Timeline |

### 2. Activity Log (`mobile_activities` table)

Every check-in and check-out creates an activity record:

```javascript
{
  id: "1736789530123",
  vehicle_id: "abc123",
  vehicle_number: "MH-12-AB-1234",
  activity_type: "check_out",  // or "check_in"
  user_name: "John Doe",
  user_email: "john@example.com",
  timestamp: "2026-01-13T23:52:10Z",
  metadata: {
    battery_percentage: 85,
    charging_type: "AC",
    inspection_items_checked: 20,
    photos_captured: 9,
    issues_reported: 2,
    issue_details: [
      "Battery Health & Charge Level",
      "Charging Port Condition"
    ],
    driver_id: "driver123",
    driver_name: "Rajesh Kumar"
  }
}
```

**Admin Panel Location**: Recent Activities section, Activity Timeline

### 3. Maintenance Jobs (`mobile_maintenance_jobs` table)

When issues are marked during inspection:

```javascript
{
  job_id: "auto-generated",
  vehicle_id: "abc123",
  job_category: "issue",
  issue_type: "Inspection Issue",
  description: "Issue detected during check-out inspection: Battery Health & Charge Level",
  diagnosis_date: "2026-01-13T23:52:10Z",
  status: "pending_diagnosis",
  created_at: "2026-01-13T23:52:10Z"
}
```

**Admin Panel Location**: Maintenance Jobs section, Vehicle Details → Maintenance Tab

### 4. Inventory Photos (`mobile_inventory_photos` table)

Photos captured during check-in/out:

```javascript
{
  photo_id: "auto-generated",
  vehicle_id: "abc123",
  category: "exterior_front",
  photo_url: "https://supabase.co/storage/v1/object/public/...",
  captured_at: "2026-01-13T23:52:10Z",
  captured_by: "john@example.com"
}
```

**Admin Panel Location**: Vehicle Details → Photos Tab, Inventory Photos Gallery

### 5. Driver Attendance (`driver_attendance` table)

If a driver was assigned:

```javascript
{
  attendance_id: "auto-generated",
  driver_id: "driver123",
  vehicle_id: "abc123",
  activity_type: "check_out",
  timestamp: "2026-01-13T23:52:10Z",
  metadata: {
    vehicle_number: "MH-12-AB-1234",
    driver_name: "Rajesh Kumar",
    battery_percentage: 85,
    charging_type: "AC",
    issues_reported: 2
  }
}
```

**Admin Panel Location**: Driver Details → Attendance Log

## How to View in Admin Panel

### Option 1: Vehicle Details Page

1. **Navigate to Vehicles**
   - Go to admin panel
   - Click on "Vehicles" or "Kanban Board"

2. **Select a Vehicle**
   - Click on any vehicle card
   - Opens vehicle details page

3. **View Check-In/Out Data**
   - **Overview Tab**: Status, battery level, last charge type
   - **Inspection Tab**: Daily checks (inspection checklist)
   - **Photos Tab**: Inventory photos
   - **Maintenance Tab**: Issues reported
   - **Timeline Tab**: Check-in/out history

### Option 2: Recent Activities

1. **Navigate to Dashboard**
   - Go to admin panel home

2. **Recent Activities Section**
   - Shows all check-in/out activities
   - Click on an activity to see details

3. **Activity Details**
   - User who performed action
   - Timestamp
   - Battery percentage
   - Charging type
   - Issues reported
   - Photos captured
   - Driver assigned

### Option 3: Maintenance Jobs

1. **Navigate to Maintenance**
   - Go to "Maintenance" or "Jobs" section

2. **Filter by Type**
   - Filter: "Inspection Issue"
   - Shows all issues from check-in/out

3. **View Issue Details**
   - Which inspection item failed
   - When it was reported
   - Which vehicle
   - Current status

### Option 4: Reports & Analytics

1. **Navigate to Reports**
   - Go to "Reports" or "Analytics"

2. **Check-In/Out Report**
   - Shows all check-in/out activities
   - Filter by date, vehicle, user
   - Export to CSV/PDF

3. **Inspection Report**
   - Shows inspection results
   - Pass/fail rates
   - Common issues

## Example: Complete Check-Out Data Flow

### Mobile App (User fills form):
```
Vehicle: MH-12-AB-1234
Driver: Rajesh Kumar
Battery: 85%
Charging Type: AC
Inspection Items:
  ✅ Battery Health - OK
  ❌ Charging Port - Issue
  ✅ Motor Sound - OK
  ... (20 items total)
Photos: 9 captured
```

### Database (Data saved to):

#### 1. `crm_vehicles` table:
```sql
UPDATE crm_vehicles SET
  is_vehicle_in = false,
  status = 'maintenance',  -- Because issue found
  battery_level = 85,
  last_charge_type = 'AC',
  daily_checks = '{"battery_health": true, "charging_port": false, ...}',
  service_attention = true,
  inventory_photo_count = 9,
  last_inventory_time = NOW(),
  last_check_out_time = NOW()
WHERE vehicle_id = 'abc123';
```

#### 2. `mobile_activities` table:
```sql
INSERT INTO mobile_activities (
  vehicle_id, activity_type, user_name, metadata
) VALUES (
  'abc123',
  'check_out',
  'John Doe',
  '{"battery_percentage": 85, "charging_type": "AC", "issues_reported": 1, ...}'
);
```

#### 3. `mobile_maintenance_jobs` table:
```sql
INSERT INTO mobile_maintenance_jobs (
  vehicle_id, issue_type, description
) VALUES (
  'abc123',
  'Inspection Issue',
  'Issue detected during check-out inspection: Charging Port Condition'
);
```

#### 4. `mobile_inventory_photos` table:
```sql
INSERT INTO mobile_inventory_photos (
  vehicle_id, category, photo_url
) VALUES
  ('abc123', 'exterior_front', 'https://...'),
  ('abc123', 'exterior_rear', 'https://...'),
  ... (9 rows total)
```

### Admin Panel (What admin sees):

#### Dashboard - Recent Activities:
```
🚗 Check-Out: MH-12-AB-1234
   By: John Doe
   Time: 2026-01-13 23:52
   Battery: 85% | Charging: AC
   ⚠️ 1 issue reported
   📸 9 photos captured
   👤 Driver: Rajesh Kumar
```

#### Vehicle Details Page:
```
Vehicle: MH-12-AB-1234
Status: 🔧 Maintenance
Battery: 85% (AC Charging)
Last Check-Out: 2026-01-13 23:52

⚠️ Service Attention Required

Inspection Results:
  ✅ Battery Health - OK
  ❌ Charging Port - Issue
  ✅ Motor Sound - OK
  ...

Photos: 9 captured
```

#### Maintenance Jobs:
```
🔧 New Issue: Charging Port Condition
   Vehicle: MH-12-AB-1234
   Reported: 2026-01-13 23:52
   Type: Inspection Issue
   Status: Pending Diagnosis
   Description: Issue detected during check-out inspection
```

## Verification Queries

To verify data is being saved, run these SQL queries in Supabase:

### Check Recent Check-Outs:
```sql
SELECT 
  vehicle_id,
  registration_number,
  status,
  battery_level,
  last_charge_type,
  is_vehicle_in,
  last_check_out_time,
  service_attention
FROM crm_vehicles
WHERE last_check_out_time > NOW() - INTERVAL '1 day'
ORDER BY last_check_out_time DESC;
```

### Check Recent Activities:
```sql
SELECT 
  activity_type,
  vehicle_number,
  user_name,
  timestamp,
  metadata
FROM mobile_activities
WHERE activity_type IN ('check_in', 'check_out')
ORDER BY timestamp DESC
LIMIT 10;
```

### Check Inspection Issues:
```sql
SELECT 
  vehicle_id,
  issue_type,
  description,
  diagnosis_date,
  status
FROM mobile_maintenance_jobs
WHERE issue_type = 'Inspection Issue'
ORDER BY diagnosis_date DESC;
```

### Check Inventory Photos:
```sql
SELECT 
  vehicle_id,
  category,
  photo_url,
  captured_at,
  captured_by
FROM mobile_inventory_photos
ORDER BY captured_at DESC
LIMIT 20;
```

## Summary

✅ **All data IS being saved** to the database  
✅ **All data IS visible** in the admin panel  
✅ **Multiple views available**: Vehicle details, activities, maintenance, photos  
✅ **Real-time updates**: Data appears immediately after check-in/out  
✅ **Complete audit trail**: Every action is logged with full details  

The system is working as designed - all check-in/out data is stored and accessible in the admin panel!

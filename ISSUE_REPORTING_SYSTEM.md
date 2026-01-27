# Automatic Issue Reporting & Admin Notification System

## Overview
When a user marks an inspection item as **"Issue"** instead of **"OK"** during check-in or check-out, the system automatically:
1. Creates a maintenance job in the database
2. Notifies the admin panel
3. Sets the vehicle status to "Maintenance"
4. Flags the vehicle for service attention

## How It Works

### User Perspective

#### During Check-In/Check-Out:

1. **Fill Inspection Checklist**
   - User sees inspection items (e.g., "Battery Health & Charge Level")
   - Each item has two buttons: **OK** and **Issue**

2. **Mark Items as Issue**
   - User taps **Issue** button for problematic items
   - Button turns red to indicate issue selected
   - Multiple items can be marked as issues

3. **Complete Check-In/Out**
   - User fills rest of the form (battery, charging type, photos)
   - Clicks "Complete Check-In" or "Complete Check-Out"

4. **Automatic Notification**
   - System shows: **"X issue(s) reported to admin"** (orange notification)
   - Then shows: **"Vehicle checked in/out successfully"** (green notification)
   - Issues are automatically sent to admin panel

### What Happens Behind the Scenes

#### Step 1: Issue Detection
```dart
// System scans the inspection checklist
// Finds items where value == false (Issue selected)
// Collects the labels of problematic items
```

#### Step 2: Maintenance Job Creation
For each issue found, the system creates a maintenance job:
```javascript
{
  vehicle_id: "abc123",
  job_category: "issue",
  issue_type: "Inspection Issue",
  description: "Issue detected during check-out inspection: Battery Health & Charge Level",
  diagnosis_date: "2026-01-13T16:03:41Z",
  status: "pending_diagnosis"
}
```

#### Step 3: Vehicle Status Update
- **Status**: Changed to `'maintenance'` (if issues found)
- **Service Attention**: Set to `true`
- **Daily Checks**: Saved with issue flags

#### Step 4: Activity Logging
The activity log includes:
```javascript
{
  activity_type: "check_out",
  metadata: {
    issues_reported: 2,
    issue_details: [
      "Battery Health & Charge Level",
      "Charging Port Condition"
    ]
  }
}
```

## Admin Panel Integration

### How Admin Sees the Issues

1. **Maintenance Jobs Table** (`mobile_maintenance_jobs`)
   - New rows appear for each issue
   - Status: "pending_diagnosis"
   - Type: "Inspection Issue"
   - Description includes the specific inspection item

2. **Vehicle Status**
   - Vehicle status changes to "Maintenance"
   - `service_attention` flag is set to `true`
   - Admin can filter vehicles needing attention

3. **Activity Feed**
   - Shows check-in/out activity
   - Includes count of issues reported
   - Lists specific issues in metadata

## Example Scenarios

### Scenario 1: Single Issue During Check-Out

**User Actions:**
1. Selects vehicle MH-12-AB-1234
2. Marks "Battery Health" as **Issue**
3. Marks other items as **OK**
4. Completes check-out

**System Response:**
- Creates 1 maintenance job for "Battery Health"
- Sets vehicle status to "Maintenance"
- Shows: "1 issue(s) reported to admin"
- Admin sees new maintenance job in panel

### Scenario 2: Multiple Issues During Check-In

**User Actions:**
1. Selects vehicle MH-15-CD-5678
2. Marks 3 items as **Issue**:
   - "Charging Port Condition"
   - "Battery Cooling System"
   - "Motor Sound & Performance"
3. Completes check-in

**System Response:**
- Creates 3 separate maintenance jobs
- Sets vehicle status to "Maintenance"
- Shows: "3 issue(s) reported to admin"
- Admin sees 3 new maintenance jobs

### Scenario 3: No Issues (All OK)

**User Actions:**
1. Selects vehicle
2. Marks all items as **OK**
3. Completes check-out

**System Response:**
- No maintenance jobs created
- Vehicle status set to "Active" (check-out) or "Charging" (check-in)
- No issue notification shown
- Normal check-out completion

## Database Tables Affected

### 1. `mobile_maintenance_jobs`
New rows inserted for each issue:
```sql
INSERT INTO mobile_maintenance_jobs (
  vehicle_id,
  job_category,
  issue_type,
  description,
  diagnosis_date,
  status
) VALUES (
  'vehicle-id',
  'issue',
  'Inspection Issue',
  'Issue detected during check-out inspection: Battery Health',
  NOW(),
  'pending_diagnosis'
);
```

### 2. `crm_vehicles`
Updated fields:
```sql
UPDATE crm_vehicles SET
  status = 'maintenance',           -- If issues found
  service_attention = true,         -- Flag for admin
  daily_checks = {...},             -- Includes issue flags
  last_inspection_date = CURRENT_DATE
WHERE vehicle_id = 'vehicle-id';
```

### 3. `mobile_activities`
Activity logged with issue details:
```sql
INSERT INTO mobile_activities (
  vehicle_id,
  activity_type,
  metadata
) VALUES (
  'vehicle-id',
  'check_out',
  '{"issues_reported": 2, "issue_details": ["Battery Health", "Charging Port"]}'
);
```

## Console Logs

When issues are reported, you'll see these logs:

```
🚗 Starting check-out process for MH-12-AB-1234
⚠️ Creating maintenance jobs for 2 issues...
✅ Created maintenance job for: Battery Health & Charge Level
✅ Created maintenance job for: Charging Port Condition
📸 Saving 9 inventory photos...
💾 Updating vehicle data in database...
✅ Check-out completed successfully
⚠️ Admin notified about 2 issue(s)
```

## User Notifications

### Issue Reported Notification (Orange)
```
"2 issue(s) reported to admin"
```
- Shown for 3 seconds
- Orange background (warning color)
- Appears before success message

### Success Notification (Green)
```
"MH-12-AB-1234 checked out successfully"
```
- Shown after issue notification
- Green background (success color)
- Confirms completion

## Benefits

### For Mobile Users
✅ Quick and easy issue reporting  
✅ No need to manually create maintenance tickets  
✅ Immediate confirmation that admin was notified  
✅ Continue with check-in/out process seamlessly  

### For Admin
✅ Automatic issue tracking  
✅ Real-time notifications of vehicle problems  
✅ Detailed information about each issue  
✅ Vehicles automatically flagged for attention  
✅ Complete audit trail in activity logs  

### For Operations
✅ Faster response to vehicle issues  
✅ Better maintenance tracking  
✅ Reduced downtime  
✅ Improved vehicle health monitoring  
✅ Data-driven maintenance decisions  

## Testing the Feature

### Test Case 1: Report Single Issue

1. Open check-out screen
2. Select a vehicle
3. Mark one item as **Issue**
4. Complete check-out
5. **Expected**:
   - Orange notification: "1 issue(s) reported to admin"
   - Green notification: "Vehicle checked out successfully"
   - Console log: "⚠️ Admin notified about 1 issue(s)"

### Test Case 2: Report Multiple Issues

1. Open check-in screen
2. Select a vehicle
3. Mark 3 items as **Issue**
4. Complete check-in
5. **Expected**:
   - Orange notification: "3 issue(s) reported to admin"
   - Vehicle status changes to "Maintenance"
   - 3 maintenance jobs created in database

### Test Case 3: Verify in Admin Panel

1. After reporting issues from mobile
2. Open admin panel
3. Navigate to maintenance jobs
4. **Expected**:
   - See new maintenance jobs
   - Type: "Inspection Issue"
   - Description includes inspection item name
   - Status: "pending_diagnosis"

## Important Notes

- ✅ **Non-blocking**: Issue reporting doesn't prevent check-in/out
- ✅ **Resilient**: If one issue fails to save, others still process
- ✅ **Automatic**: No manual intervention needed
- ✅ **Detailed**: Each issue gets its own maintenance job
- ✅ **Traceable**: Full audit trail in activity logs

## Future Enhancements

Potential improvements:
- 📧 Email notifications to admin
- 📱 Push notifications to admin mobile app
- 📊 Issue analytics dashboard
- 🔔 Real-time alerts for critical issues
- 📝 Issue priority levels
- 🎯 Auto-assignment to maintenance team

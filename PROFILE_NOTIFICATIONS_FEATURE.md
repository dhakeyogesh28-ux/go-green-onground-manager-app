# Profile and Notifications Feature Implementation

This document describes the implementation of the **Edit Profile** and **Working Notifications** features in the mobile app.

## Features Implemented

### 1. Edit Profile Screen ✅

Users can now edit their profile information including:
- **Full Name** - Editable text field with validation
- **Mobile Number** - Editable with 10-digit validation
- **Email** - Read-only (cannot be changed)
- **Role** - Read-only (fixed as "On-Ground Manager")

#### Files Created/Modified:
- **`lib/screens/edit_profile_screen.dart`** - New screen for editing profile
- **`lib/screens/profile_screen.dart`** - Added navigation to edit profile screen
- **`lib/providers/app_provider.dart`** - Added `userMobile` field and `updateUserProfile()` method
- **`lib/services/supabase_service.dart`** - Added `updateUserProfile()` method to update database

#### How It Works:
1. User clicks "Edit Profile" button on Profile Screen
2. Edit Profile Screen opens with pre-filled data
3. User can modify name and mobile number
4. Form validates input (name required, mobile must be 10 digits)
5. On save, data is updated in:
   - Supabase `users` table
   - Local SharedPreferences
   - AppProvider state
6. Success/error message is shown
7. Profile screen reflects updated data

#### Database Changes Required:
Run the following SQL migration in your Supabase SQL Editor:

```sql
-- Add mobile field to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS mobile VARCHAR(20);
CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile);
```

Or use the provided migration file: `database_add_mobile_field.sql`

### 2. Working Notifications Screen ✅

The notifications screen now displays real data from the database:

#### Notification Sources:
1. **Activity Notifications** - From `mobile_activities` table
   - Check-in events
   - Check-out events
   
2. **Maintenance Notifications** - From `mobile_maintenance_jobs` table
   - Reported issues
   - Maintenance status updates

#### Files Created/Modified:
- **`lib/services/notification_service.dart`** - New service to fetch notifications
- **`lib/screens/notifications_screen.dart`** - Updated to use real data

#### Features:
- ✅ Real-time data from database
- ✅ Pull-to-refresh functionality
- ✅ Loading states
- ✅ Error handling with retry
- ✅ Empty state when no notifications
- ✅ Relative timestamps ("2 hours ago", "1 day ago", etc.)
- ✅ Different icons and colors for notification types
- ✅ Visual indicator for unread notifications (blue dot)
- ✅ Notification count in header

#### Notification Types:
| Type | Icon | Color | Source |
|------|------|-------|--------|
| Assignment | Clipboard Check | Green | Check-in activities |
| Update | Refresh | Blue | Check-out activities |
| Maintenance | Wrench | Orange | Maintenance jobs |
| Message | Message Square | Purple | Future use |

## Usage Guide

### For Users

#### Editing Profile:
1. Open the app and navigate to **Profile** screen
2. Click **Edit Profile** button
3. Update your name or mobile number
4. Click **Save Changes**
5. Wait for confirmation message

#### Viewing Notifications:
1. Open the app and navigate to **Notifications** screen
2. View all recent activities and maintenance updates
3. Pull down to refresh and get latest notifications
4. Unread notifications have a blue background and blue dot

### For Developers

#### Adding New Notification Types:

Edit `lib/services/notification_service.dart`:

```dart
// Add new method to fetch your notification type
Future<List<Map<String, dynamic>>> getYourNotifications() async {
  // Fetch from database
  final response = await _client.from('your_table').select('*');
  
  // Transform to notification format
  return response.map((item) => {
    'id': item['id'],
    'type': 'your_type',
    'title': 'Your Title',
    'message': 'Your message',
    'timestamp': item['created_at'],
    'isRead': false,
  }).toList();
}

// Add to getAllNotifications() method
final yourNotifications = await getYourNotifications();
allNotifications.addAll(yourNotifications);
```

#### Updating Profile Fields:

To add more editable fields:

1. Add field to `users` table in database
2. Add getter/setter in `AppProvider`
3. Load/save in `_loadSettings()` and `login()` methods
4. Add to `updateUserProfile()` method
5. Add form field in `edit_profile_screen.dart`

## Database Schema

### Users Table (Updated)
```sql
CREATE TABLE users (
  user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  mobile VARCHAR(20),           -- NEW FIELD
  hub VARCHAR(100),
  role VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Mobile Activities Table (Used for Notifications)
```sql
CREATE TABLE mobile_activities (
  activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID REFERENCES crm_vehicles(vehicle_id),
  vehicle_number VARCHAR(50) NOT NULL,
  activity_type VARCHAR(50) NOT NULL,
  user_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  metadata JSONB
);
```

### Mobile Maintenance Jobs Table (Used for Notifications)
```sql
CREATE TABLE mobile_maintenance_jobs (
  job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID REFERENCES crm_vehicles(vehicle_id),
  issue_type VARCHAR(100),
  description TEXT,
  status VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);
```

## API Methods

### AppProvider Methods

```dart
// Get user mobile number
String? get userMobile => _userMobile;

// Update user profile
Future<void> updateUserProfile({
  String? fullName,
  String? mobile,
}) async
```

### SupabaseService Methods

```dart
// Update user profile in database
Future<void> updateUserProfile({
  required String email,
  String? fullName,
  String? mobile,
}) async
```

### NotificationService Methods

```dart
// Get all notifications (activities + maintenance)
Future<List<Map<String, dynamic>>> getAllNotifications({
  String? userEmail,
  int limit = 20,
}) async

// Get only activity notifications
Future<List<Map<String, dynamic>>> getNotifications({
  String? userEmail,
  int limit = 20,
}) async

// Get only maintenance notifications
Future<List<Map<String, dynamic>>> getMaintenanceNotifications({
  int limit = 10,
}) async

// Format timestamp to relative time
static String formatTimestamp(String? timestamp)
```

## Testing Checklist

### Edit Profile
- [ ] Profile screen shows current user data
- [ ] Edit Profile button navigates to edit screen
- [ ] Form fields are pre-filled with current data
- [ ] Email and Role fields are read-only
- [ ] Name validation works (required)
- [ ] Mobile validation works (10 digits)
- [ ] Save button is disabled when no changes
- [ ] Save button shows loading state
- [ ] Success message appears on successful save
- [ ] Error message appears on failure
- [ ] Profile screen updates after save
- [ ] Data persists after app restart

### Notifications
- [ ] Notifications screen loads data from database
- [ ] Loading indicator shows while fetching
- [ ] Empty state shows when no notifications
- [ ] Notifications display with correct icons and colors
- [ ] Timestamps show relative time
- [ ] Unread notifications have blue background
- [ ] Pull-to-refresh works
- [ ] Refresh button in app bar works
- [ ] Error state shows with retry button
- [ ] Notification count shows in header

## Troubleshooting

### Profile Update Fails
1. Check if `mobile` column exists in `users` table
2. Run migration: `database_add_mobile_field.sql`
3. Verify RLS policies allow updates to `users` table
4. Check console for error messages

### Notifications Not Loading
1. Verify `mobile_activities` table has data
2. Check RLS policies on `mobile_activities` table
3. Ensure user is authenticated
4. Check console for error messages
5. Try pull-to-refresh

### Mobile Number Validation Issues
- Mobile number must be exactly 10 digits
- Only numbers allowed (no spaces or special characters)
- Leave empty if user doesn't want to add mobile number

## Future Enhancements

### Profile
- [ ] Profile photo upload
- [ ] Change password functionality
- [ ] Email verification
- [ ] Two-factor authentication
- [ ] Activity history

### Notifications
- [ ] Mark as read functionality
- [ ] Delete notifications
- [ ] Filter by type
- [ ] Search notifications
- [ ] Push notifications
- [ ] Notification settings/preferences
- [ ] In-app notification badges

## Files Modified Summary

### New Files:
1. `lib/screens/edit_profile_screen.dart` - Edit profile UI
2. `lib/services/notification_service.dart` - Notification data service
3. `database_add_mobile_field.sql` - Database migration

### Modified Files:
1. `lib/screens/profile_screen.dart` - Added edit button navigation
2. `lib/screens/notifications_screen.dart` - Complete rewrite with real data
3. `lib/providers/app_provider.dart` - Added mobile field and update method
4. `lib/services/supabase_service.dart` - Added updateUserProfile method

## Support

For issues or questions:
1. Check console logs for error messages
2. Verify database schema matches documentation
3. Ensure RLS policies are configured correctly
4. Check that Supabase connection is working

---

**Last Updated:** 2026-01-14
**Version:** 1.0.0

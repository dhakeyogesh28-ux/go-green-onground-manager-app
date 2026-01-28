# Data Persistence Guide for GGmanager App

## Overview
The GGmanager app uses `shared_preferences` package to persist data locally. This ensures that your data remains available even after closing and reopening the app.

## What Data is Persisted?

### 1. **User Authentication Data**
- `isLoggedIn` - Boolean flag indicating login status
- `userEmail` - User's email address
- `selectedHub` - Selected hub (Nashik, Pune Station 1, or Pune Station 2)
- `userName` - User's full name
- `lastRoute` - Last visited route for session recovery

### 2. **Offline Data**
- `reportedIssues` - Issues reported while offline
- `inspectionResults` - Inspection results saved locally
- `inventoryPhotos` - Inventory photo paths
- `pendingOperations` - Operations queued for sync with Supabase

## How It Works

### On App Start
1. `AppProvider` is initialized
2. `_loadSettings()` is called automatically
3. Data is loaded from SharedPreferences (browser's localStorage on web)
4. If user is logged in, vehicles are loaded from Supabase
5. Pending operations are synced

### On Login
1. User credentials are validated against Supabase
2. Login state is saved to SharedPreferences
3. User data (email, hub, name) is persisted
4. Vehicles are loaded from Supabase

### On Data Changes
- Issues, inspections, and photos are automatically saved to SharedPreferences
- Changes are also synced to Supabase when online
- If offline, operations are queued for later sync

## Testing Data Persistence

### Step 1: Check Browser Console
1. Open Chrome DevTools (F12)
2. Go to the **Console** tab
3. Look for these log messages:
   - `🔄 AppProvider: Loading persisted data...`
   - `💾 AppProvider: User data saved to SharedPreferences:`
   - `✅ AppProvider: INITIALIZED. Total data loaded successfully`

### Step 2: Check localStorage
1. Open Chrome DevTools (F12)
2. Go to **Application** tab
3. Expand **Local Storage** in the left sidebar
4. Click on your app's URL (e.g., `http://localhost:xxxxx`)
5. You should see keys like:
   - `flutter.isLoggedIn`
   - `flutter.userEmail`
   - `flutter.selectedHub`
   - `flutter.userName`

### Step 3: Test Persistence
1. **Login** to the app
2. Navigate to a vehicle or perform some actions
3. **Close the browser tab** (not just refresh)
4. **Reopen** the app at the same URL
5. You should be automatically logged in

## Common Issues and Solutions

### Issue 1: Data Not Persisting on Web
**Cause**: Browser settings or incognito mode
**Solution**: 
- Make sure you're not in Incognito/Private mode
- Check browser settings - ensure cookies and site data are allowed
- Use the same URL/port each time

### Issue 2: Data Lost After Restart
**Cause**: Different port number after restart
**Solution**:
- When running `flutter run -d chrome`, note the port number
- Always use the same URL to access the app
- Alternatively, specify a fixed port: `flutter run -d chrome --web-port=8080`

### Issue 3: Data Not Loading
**Cause**: Initialization timing issue
**Solution**:
- Check console for error messages
- Ensure Supabase is properly configured
- Verify internet connection for Supabase sync

## Best Practices

### For Development
1. **Use a fixed port** to maintain localStorage across restarts:
   ```bash
   flutter run -d chrome --web-port=8080
   ```

2. **Monitor console logs** to see when data is saved/loaded

3. **Check localStorage** in DevTools to verify data is actually saved

### For Production
1. **Build for production** to ensure proper optimization:
   ```bash
   flutter build web
   ```

2. **Deploy to a fixed URL** so users always access the same origin

3. **Implement proper error handling** for offline scenarios

## Debugging Commands

### View All Stored Data
Open browser console and run:
```javascript
// List all localStorage keys
Object.keys(localStorage).forEach(key => {
  console.log(key, '=', localStorage.getItem(key));
});
```

### Clear All Data
Open browser console and run:
```javascript
localStorage.clear();
```

### Check Specific Value
Open browser console and run:
```javascript
console.log('isLoggedIn:', localStorage.getItem('flutter.isLoggedIn'));
console.log('userEmail:', localStorage.getItem('flutter.userEmail'));
```

## Next Steps

1. **Login to the app** and check the console for persistence logs
2. **Close and reopen** the browser tab to verify data persists
3. **Check localStorage** in DevTools to see stored data
4. If issues persist, check the troubleshooting section above

## Important Notes

- On **Flutter Web**, data is stored in browser's localStorage
- On **Mobile** (Android/iOS), data is stored in native storage
- Each URL/origin has separate storage
- Clearing browser data will clear the app's stored data
- Incognito mode does NOT persist data after closing

# Testing Data Persistence - Quick Guide

## Current Status
✅ Enhanced logging has been added to track data persistence
✅ The app now shows detailed logs when saving and loading data

## How to Test Right Now

### Step 1: Open Browser DevTools
1. In your Chrome browser where the app is running, press **F12**
2. Click on the **Console** tab

### Step 2: Login to the App
1. Enter your credentials and login
2. Watch the console - you should see logs like:
   ```
   🔐 AppProvider: LOGIN ACTION TRIGGERED for your@email.com at Nashik
   💾 AppProvider: User data saved to SharedPreferences:
      - isLoggedIn: true
      - userEmail: your@email.com
      - selectedHub: Nashik
      - userName: Your Name
   ✅ AppProvider: Login state updated. Notifying listeners...
   ```

### Step 3: Check localStorage
1. In DevTools, click on the **Application** tab
2. In the left sidebar, expand **Local Storage**
3. Click on your app's URL (e.g., `http://localhost:xxxxx`)
4. You should see entries like:
   - `flutter.isLoggedIn` = `true`
   - `flutter.userEmail` = `your@email.com`
   - `flutter.selectedHub` = `Nashik`

### Step 4: Test Persistence
1. **Close the browser tab** completely
2. **Reopen** the app by going to the same URL
3. Watch the console - you should see:
   ```
   🔄 AppProvider: Loading persisted data...
      - isLoggedIn: true
      - userEmail: your@email.com
      - selectedHub: Nashik
      - userName: Your Name
   ✅ AppProvider: INITIALIZED. Total data loaded successfully
   🔄 User is logged in, loading vehicles from Supabase...
   ```
4. You should be **automatically logged in** without entering credentials again

## ⚠️ IMPORTANT: Why Data Might Not Persist

### Problem: Different Port Numbers
When you run `flutter run -d chrome`, Flutter might use a different port each time:
- First run: `http://localhost:50123`
- Second run: `http://localhost:50456`

**Each port has separate localStorage!**

### Solution: Use a Fixed Port

1. **Stop the current app** (press `q` in the terminal or close the browser)
2. **Run with a fixed port**:
   ```bash
   flutter run -d chrome --web-port=8080
   ```
3. Now your app will always run at `http://localhost:8080`
4. Data will persist across restarts!

## Quick Fix Right Now

1. Note the current URL in your browser (e.g., `http://localhost:50123`)
2. **Bookmark this URL** or write it down
3. Always use this exact URL to access the app
4. As long as you use the same URL, your data will persist

## Next Steps

For permanent solution:
1. Stop the current Flutter app
2. Run: `flutter run -d chrome --web-port=8080`
3. Always access at: `http://localhost:8080`
4. Your data will now persist reliably!

## Verification Checklist

- [ ] I can see the persistence logs in the console
- [ ] I can see data in Application > Local Storage
- [ ] I'm using the same URL/port each time
- [ ] When I close and reopen the tab, I'm still logged in
- [ ] My data (vehicles, issues, photos) is still there

## Still Having Issues?

Check:
1. Are you in **Incognito/Private mode**? (Data won't persist)
2. Are you using the **same URL** each time?
3. Did you **clear browser data** recently?
4. Check browser settings - are cookies/site data allowed?

## Console Commands for Debugging

Open browser console and paste:

```javascript
// Check if data is stored
console.log('Login Status:', localStorage.getItem('flutter.isLoggedIn'));
console.log('User Email:', localStorage.getItem('flutter.userEmail'));
console.log('Selected Hub:', localStorage.getItem('flutter.selectedHub'));

// List all stored data
Object.keys(localStorage).filter(k => k.startsWith('flutter.')).forEach(key => {
  console.log(key, '=', localStorage.getItem(key));
});
```

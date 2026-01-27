---
description: Run the app with fixed port for better data persistence
---

# Running the App with Fixed Port

To ensure data persists properly during development on web, use a fixed port:

// turbo
```bash
flutter run -d chrome --web-port=8080
```

This ensures that:
1. The app always runs on `http://localhost:8080`
2. Browser's localStorage is consistent across restarts
3. Your login session and data persist when you close and reopen the app

## Alternative: Run on Different Port

If port 8080 is busy, use another port:

```bash
flutter run -d chrome --web-port=9090
```

## For Mobile Testing

To run on a connected Android device:

```bash
flutter run -d android
```

To run on iOS simulator:

```bash
flutter run -d ios
```

## Checking Data Persistence

After running the app:

1. Login to the app
2. Open Chrome DevTools (F12)
3. Go to Console tab - you should see logs like:
   - `🔄 AppProvider: Loading persisted data...`
   - `💾 AppProvider: User data saved to SharedPreferences:`
4. Go to Application > Local Storage to see stored data
5. Close the browser tab
6. Reopen at the same URL - you should still be logged in

# DC Fast Charging Limit Feature

## Overview
This feature enforces a charging pattern where vehicles must use AC charging after every 5 consecutive DC fast charges. This is implemented to ensure battery health and longevity.

## Business Rule
**After 5 consecutive DC fast charges, the vehicle MUST be charged with AC before DC charging is allowed again.**

- If AC charging is used before reaching 5 DC charges, the counter resets to 0
- The counter is tracked per vehicle and persists across check-ins and check-outs

## Implementation Details

### Visual Indicators

#### 1. Counter Badge (0-5 DC charges)
- **Blue badge (1-2 charges)**: Shows count like "1/5", "2/5"
- **Orange badge (3-4 charges)**: Warning state, shows "3/5", "4/5"
- **Red badge (5 charges)**: Blocked state, shows "5/5"

#### 2. Card Appearance
- **Normal**: White background, gray border
- **Selected**: Green background, green border
- **Warning (3-4 charges)**: Orange tint background, orange border, shows "X left"
- **Blocked (5 charges)**: Red tint background, red border, shows "Use AC first!", ban icon, disabled tap

### User Flow

#### Scenario 1: Normal DC Charging (Under Limit)
1. User selects vehicle
2. Counter loads from database (e.g., 2/5)
3. User selects "DC Fast Charging" - card shows counter
4. User completes check-in/check-out
5. Counter increments to 3/5 and saves to database

#### Scenario 2: Warning State (3-4 Charges)
1. User selects vehicle with 3 DC charges
2. DC card shows orange warning with "2 left" message
3. User can still select DC charging
4. After selection, counter becomes 4/5
5. Next time: shows "1 left" in orange

#### Scenario 3: Blocked State (5 Charges)
1. User selects vehicle with 5 DC charges
2. DC card shows:
   - Red background
   - Ban icon instead of lightning
   - "Use AC first!" message
   - Card is disabled (cannot tap)
3. User MUST select AC charging
4. After AC charging, counter resets to 0/5

#### Scenario 4: AC Charging (Reset)
1. User selects AC charging at any point
2. Counter resets to 0
3. DC charging becomes available again
4. Database updated with consecutive_dc_charges = 0

### Database Schema

#### New Field in `crm_vehicles` table:
```sql
consecutive_dc_charges INTEGER DEFAULT 0
```

This field tracks the number of consecutive DC charges for each vehicle.

### Code Changes

#### Files Modified:
1. **`lib/screens/check_in_screen.dart`**
   - Added `_consecutiveDCCharges` and `_dcChargingBlocked` state variables
   - Added `_loadDCChargeCount()` method
   - Added `_updateDCChargeCount()` method
   - Updated `_searchVehicle()` to load counter when vehicle is selected
   - Updated `_handleCheckIn()` to validate and update counter
   - Enhanced `_buildChargingTypeCard()` with visual indicators

2. **`lib/screens/check_out_screen.dart`**
   - Same changes as check-in screen
   - Updated `_handleCheckOut()` to validate and update counter

### Validation Logic

```dart
// Check if DC is blocked
if (_selectedChargingType == 'dc' && _dcChargingBlocked) {
  // Show error message
  // Prevent check-in/check-out
  return;
}

// Update counter after successful check-in/check-out
if (_selectedChargingType == 'dc') {
  _consecutiveDCCharges++;
  _dcChargingBlocked = _consecutiveDCCharges >= 5;
} else if (_selectedChargingType == 'ac') {
  _consecutiveDCCharges = 0;
  _dcChargingBlocked = false;
}
```

### Error Messages

1. **No charging type selected**:
   ```
   "Please select a charging type"
   (Orange background)
   ```

2. **DC charging blocked**:
   ```
   "DC charging blocked! Please use AC charging first."
   (Red background, 3 seconds duration)
   ```

## Testing Scenarios

### Test 1: Normal Flow
1. Check in vehicle with DC (0→1)
2. Check out with DC (1→2)
3. Check in with DC (2→3) - Should show orange warning
4. Check out with DC (3→4) - Should show orange warning
5. Check in with DC (4→5) - Should block next DC
6. Try to check out with DC - Should be BLOCKED
7. Check out with AC - Counter resets to 0

### Test 2: Early Reset
1. Check in with DC (0→1)
2. Check out with DC (1→2)
3. Check in with AC (2→0) - Counter resets
4. Check out with DC (0→1) - Starts fresh

### Test 3: Visual Indicators
1. At 0-2 charges: Blue badge
2. At 3-4 charges: Orange badge + warning text
3. At 5 charges: Red badge + blocked state + ban icon

## Benefits

1. **Battery Health**: Prevents excessive DC fast charging
2. **User Guidance**: Clear visual feedback on charging status
3. **Enforcement**: System prevents violation of the rule
4. **Flexibility**: Allows AC charging at any time to reset

## Future Enhancements

1. Add notification/alert when approaching limit (at 3 charges)
2. Generate reports on DC vs AC charging patterns
3. Add admin override capability
4. Track charging history per vehicle
5. Add configurable limit (currently hardcoded to 5)

## Notes

- The counter is vehicle-specific (not user-specific)
- The counter persists across app restarts
- The counter is stored in the database for reliability
- Hot reload will pick up the changes immediately

---

**Implementation Date:** January 12, 2026  
**Status:** ✅ Complete and Ready for Testing

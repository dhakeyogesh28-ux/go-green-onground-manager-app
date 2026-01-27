import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @hub.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get hub;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @totalVehicles.
  ///
  /// In en, this message translates to:
  /// **'Total Vehicles'**
  String get totalVehicles;

  /// No description provided for @inHub.
  ///
  /// In en, this message translates to:
  /// **'In Hub'**
  String get inHub;

  /// No description provided for @out.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get out;

  /// No description provided for @ongoingServices.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Services'**
  String get ongoingServices;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @inventoryPhotos.
  ///
  /// In en, this message translates to:
  /// **'Inventory Photos'**
  String get inventoryPhotos;

  /// No description provided for @inspectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Inspection Summary'**
  String get inspectionSummary;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @selectHub.
  ///
  /// In en, this message translates to:
  /// **'Select Hub'**
  String get selectHub;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @assignedVehicles.
  ///
  /// In en, this message translates to:
  /// **'All Vehicles'**
  String get assignedVehicles;

  /// No description provided for @allVehicles.
  ///
  /// In en, this message translates to:
  /// **'All Vehicles'**
  String get allVehicles;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @charging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get charging;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @vehicleManagementOverview.
  ///
  /// In en, this message translates to:
  /// **'Vehicle management overview'**
  String get vehicleManagementOverview;

  /// No description provided for @vehiclesCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Vehicles checked out'**
  String get vehiclesCheckedOut;

  /// No description provided for @totalVehiclesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Total vehicles assigned'**
  String get totalVehiclesAssigned;

  /// No description provided for @vehiclesCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Vehicles checked in'**
  String get vehiclesCheckedIn;

  /// No description provided for @vehicleManagement.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Management'**
  String get vehicleManagement;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @dailyCheck.
  ///
  /// In en, this message translates to:
  /// **'Daily Check'**
  String get dailyCheck;

  /// No description provided for @fullScan.
  ///
  /// In en, this message translates to:
  /// **'Full Scan'**
  String get fullScan;

  /// No description provided for @inHubStatus.
  ///
  /// In en, this message translates to:
  /// **'IN HUB'**
  String get inHubStatus;

  /// No description provided for @outStatus.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get outStatus;

  /// No description provided for @vehicleStatus.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Status'**
  String get vehicleStatus;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select a Status'**
  String get selectStatus;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @chargingCycle.
  ///
  /// In en, this message translates to:
  /// **'Charging Cycle'**
  String get chargingCycle;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @servicingStatus.
  ///
  /// In en, this message translates to:
  /// **'Servicing Status'**
  String get servicingStatus;

  /// No description provided for @lastService.
  ///
  /// In en, this message translates to:
  /// **'Last Service'**
  String get lastService;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @lastCharging.
  ///
  /// In en, this message translates to:
  /// **'Last Charging'**
  String get lastCharging;

  /// No description provided for @logCharging.
  ///
  /// In en, this message translates to:
  /// **'Log Charging'**
  String get logCharging;

  /// No description provided for @dailyInventory.
  ///
  /// In en, this message translates to:
  /// **'Daily Inventory / Visual Check'**
  String get dailyInventory;

  /// No description provided for @tapToToggle.
  ///
  /// In en, this message translates to:
  /// **'Tap to toggle status'**
  String get tapToToggle;

  /// No description provided for @batteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery Level'**
  String get batteryLevel;

  /// No description provided for @chargingCable.
  ///
  /// In en, this message translates to:
  /// **'Charging Cable'**
  String get chargingCable;

  /// No description provided for @tyreCondition.
  ///
  /// In en, this message translates to:
  /// **'Tyre Condition'**
  String get tyreCondition;

  /// No description provided for @visibleDamage.
  ///
  /// In en, this message translates to:
  /// **'Visible Damage'**
  String get visibleDamage;

  /// No description provided for @requiredPhotos.
  ///
  /// In en, this message translates to:
  /// **'Required Inventory Photos'**
  String get requiredPhotos;

  /// No description provided for @capturePhotosNow.
  ///
  /// In en, this message translates to:
  /// **'Capture Photos Now'**
  String get capturePhotosNow;

  /// No description provided for @addIssue.
  ///
  /// In en, this message translates to:
  /// **'Add Issue'**
  String get addIssue;

  /// No description provided for @batteryHVSystem.
  ///
  /// In en, this message translates to:
  /// **'Battery & HV System'**
  String get batteryHVSystem;

  /// No description provided for @sohOk.
  ///
  /// In en, this message translates to:
  /// **'SoH OK'**
  String get sohOk;

  /// No description provided for @noHvWarnings.
  ///
  /// In en, this message translates to:
  /// **'No HV warnings'**
  String get noHvWarnings;

  /// No description provided for @acCharging.
  ///
  /// In en, this message translates to:
  /// **'AC Charging'**
  String get acCharging;

  /// No description provided for @dcCharging.
  ///
  /// In en, this message translates to:
  /// **'DC Charging'**
  String get dcCharging;

  /// No description provided for @motorDrive.
  ///
  /// In en, this message translates to:
  /// **'Motor & Drive'**
  String get motorDrive;

  /// No description provided for @noAbnormalNoise.
  ///
  /// In en, this message translates to:
  /// **'No abnormal noise'**
  String get noAbnormalNoise;

  /// No description provided for @powerDeliveryNormal.
  ///
  /// In en, this message translates to:
  /// **'Power delivery normal'**
  String get powerDeliveryNormal;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get auto;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @reportedIssues.
  ///
  /// In en, this message translates to:
  /// **'Reported Issues'**
  String get reportedIssues;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @inspectionChecklist.
  ///
  /// In en, this message translates to:
  /// **'Inspection Checklist'**
  String get inspectionChecklist;

  /// No description provided for @tasksToDo.
  ///
  /// In en, this message translates to:
  /// **'Tasks (To-Do)'**
  String get tasksToDo;

  /// No description provided for @addNewTask.
  ///
  /// In en, this message translates to:
  /// **'Add new task...'**
  String get addNewTask;

  /// No description provided for @updateStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vehicle status updated to {status}'**
  String updateStatusSuccess(String status);

  /// No description provided for @allPhotosCaptured.
  ///
  /// In en, this message translates to:
  /// **'All photos captured'**
  String get allPhotosCaptured;

  /// No description provided for @captureAnglesDetails.
  ///
  /// In en, this message translates to:
  /// **'Capture all angles & details'**
  String get captureAnglesDetails;

  /// No description provided for @reviewPhotos.
  ///
  /// In en, this message translates to:
  /// **'Review Photos'**
  String get reviewPhotos;

  /// No description provided for @completeSubmitInventory.
  ///
  /// In en, this message translates to:
  /// **'Complete & Submit Inventory'**
  String get completeSubmitInventory;

  /// No description provided for @captureAllPhotosToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Capture All Photos to Submit'**
  String get captureAllPhotosToSubmit;

  /// No description provided for @vehicleMarkedAs.
  ///
  /// In en, this message translates to:
  /// **'Vehicle marked as {status}'**
  String vehicleMarkedAs(String status);

  /// No description provided for @completeInspection.
  ///
  /// In en, this message translates to:
  /// **'Complete Inspection'**
  String get completeInspection;

  /// No description provided for @videoCaptured.
  ///
  /// In en, this message translates to:
  /// **'Video Captured'**
  String get videoCaptured;

  /// No description provided for @playbackAvailable.
  ///
  /// In en, this message translates to:
  /// **'Playback available in full report'**
  String get playbackAvailable;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deleteIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Issue?'**
  String get deleteIssueTitle;

  /// No description provided for @deleteIssueConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this reported issue?'**
  String get deleteIssueConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @issueRemoved.
  ///
  /// In en, this message translates to:
  /// **'Issue removed successfully'**
  String get issueRemoved;

  /// No description provided for @noIssuesReported.
  ///
  /// In en, this message translates to:
  /// **'No issues reported yet'**
  String get noIssuesReported;

  /// No description provided for @vehicleVIN.
  ///
  /// In en, this message translates to:
  /// **'Vehicle | VIN'**
  String get vehicleVIN;

  /// No description provided for @batterySOH.
  ///
  /// In en, this message translates to:
  /// **'Battery SoH'**
  String get batterySOH;

  /// No description provided for @faults.
  ///
  /// In en, this message translates to:
  /// **'Faults'**
  String get faults;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @cooling.
  ///
  /// In en, this message translates to:
  /// **'Cooling'**
  String get cooling;

  /// No description provided for @coolantLevelOk.
  ///
  /// In en, this message translates to:
  /// **'Coolant level OK'**
  String get coolantLevelOk;

  /// No description provided for @fansPumpWorking.
  ///
  /// In en, this message translates to:
  /// **'Fans / pump working'**
  String get fansPumpWorking;

  /// No description provided for @twelveVSystem.
  ///
  /// In en, this message translates to:
  /// **'12V System'**
  String get twelveVSystem;

  /// No description provided for @twelveVbatteryOk.
  ///
  /// In en, this message translates to:
  /// **'12V Battery OK'**
  String get twelveVbatteryOk;

  /// No description provided for @brakesTires.
  ///
  /// In en, this message translates to:
  /// **'Brakes & Tires'**
  String get brakesTires;

  /// No description provided for @brakesOk.
  ///
  /// In en, this message translates to:
  /// **'Brakes OK'**
  String get brakesOk;

  /// No description provided for @tireConditionOk.
  ///
  /// In en, this message translates to:
  /// **'Tire Condition OK'**
  String get tireConditionOk;

  /// No description provided for @exterior.
  ///
  /// In en, this message translates to:
  /// **'Exterior'**
  String get exterior;

  /// No description provided for @exteriorBody.
  ///
  /// In en, this message translates to:
  /// **'Exterior & Body'**
  String get exteriorBody;

  /// No description provided for @windows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get windows;

  /// No description provided for @mirrors.
  ///
  /// In en, this message translates to:
  /// **'Mirrors'**
  String get mirrors;

  /// No description provided for @electrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get electrical;

  /// No description provided for @chargingPort.
  ///
  /// In en, this message translates to:
  /// **'Charging Port'**
  String get chargingPort;

  /// No description provided for @horn.
  ///
  /// In en, this message translates to:
  /// **'Horn'**
  String get horn;

  /// No description provided for @wipers.
  ///
  /// In en, this message translates to:
  /// **'Wipers'**
  String get wipers;

  /// No description provided for @interior.
  ///
  /// In en, this message translates to:
  /// **'Interior'**
  String get interior;

  /// No description provided for @mechanical.
  ///
  /// In en, this message translates to:
  /// **'Mechanical'**
  String get mechanical;

  /// No description provided for @dashboardDisplay.
  ///
  /// In en, this message translates to:
  /// **'Dashboard display'**
  String get dashboardDisplay;

  /// No description provided for @infotainment.
  ///
  /// In en, this message translates to:
  /// **'Infotainment system'**
  String get infotainment;

  /// No description provided for @airConditioning.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get airConditioning;

  /// No description provided for @seatAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Seat adjustments'**
  String get seatAdjustments;

  /// No description provided for @driversRemark.
  ///
  /// In en, this message translates to:
  /// **'Drivers Remark'**
  String get driversRemark;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

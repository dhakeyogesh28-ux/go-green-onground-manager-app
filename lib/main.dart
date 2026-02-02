import 'package:flutter/material.dart';
import 'package:car_license_plate/car_license_plate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'theme.dart';
import 'config/supabase_config.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vehicle_details_screen.dart';
import 'screens/add_service_screen.dart';
import 'screens/upload_photos_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_issue_screen.dart';
import 'screens/vehicle_summary_screen.dart';
import 'screens/inventory_photos_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/check_in_screen.dart';
import 'screens/check_out_screen.dart';
import 'screens/driver_list_screen.dart';
import 'screens/add_driver_screen.dart';
import 'package:mobile/models/driver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  debugPrint('✅ Supabase initialized successfully');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const OGManagerApp(),
    ),
  );
}

class OGManagerApp extends StatefulWidget {
  const OGManagerApp({super.key});

  @override
  State<OGManagerApp> createState() => _OGManagerAppState();
}

class _OGManagerAppState extends State<OGManagerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final appProvider = context.read<AppProvider>();
    _router = GoRouter(
      initialLocation: '/login',
      navigatorKey: _rootNavigatorKey,
      refreshListenable: appProvider,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/hub',
          builder: (context, state) => const HubScreen(),
        ),
        GoRoute(
          path: '/check-in',
          builder: (context, state) => const CheckInScreen(),
        ),
        GoRoute(
          path: '/check-out',
          builder: (context, state) => const CheckOutScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/vehicle/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return VehicleDetailsScreen(vehicleId: id);
          },
        ),
        GoRoute(
          path: '/add-service/:id',
          builder: (context, state) => AddServiceScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/upload-photos/:id',
          builder: (context, state) => UploadPhotosScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/add-issue/:id',
          builder: (context, state) => AddIssueScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/vehicle-summary/:id',
          builder: (context, state) => VehicleSummaryScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/inventory-photos/:id',
          builder: (context, state) => InventoryPhotosScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/drivers',
          builder: (context, state) => const DriverListScreen(),
        ),
        GoRoute(
          path: '/add-driver',
          builder: (context, state) {
            final extra = state.extra;
            debugPrint('🚀 Router: Navigating to /add-driver');
            debugPrint('📦 extra type: ${extra?.runtimeType}');
            debugPrint('📦 extra data: $extra');
            
            Driver? driver;
            if (extra is Driver) {
              driver = extra;
              debugPrint('✅ extra IS a Driver object');
            } else if (extra != null) {
              debugPrint('⚠️ extra is NOT a Driver object! It is a ${extra.runtimeType}');
            } else {
              debugPrint('ℹ️ extra is null (Add Mode)');
            }
            
            return AddDriverScreen(driver: driver);
          },
        ),
      ],
      redirect: (context, state) {
        // If not initialized, don't redirect yet
        if (!appProvider.isInitialized) {
          debugPrint('GoRouter: [WAIT] Provider not initialized. Staying at ${state.matchedLocation}');
          return null;
        }

        final isLoggedIn = appProvider.isLoggedIn;
        final currentPath = state.matchedLocation;
        final isLoggingIn = currentPath == '/login';
        
        debugPrint('GoRouter: [REDIRECT CHECK] Path: $currentPath, isLoggedIn: $isLoggedIn');

        // If not logged in and not on login page, go to login
        if (!isLoggedIn && !isLoggingIn) {
          debugPrint('GoRouter: [AUTH GUARD] Unauthorized access to $currentPath. Redirecting to /login');
          return '/login';
        }

        // Save current path for persistence if authorized
        if (isLoggedIn && !isLoggingIn && currentPath != '/') {
          appProvider.setLastRoute(currentPath);
        }
        
        // Recovery logic: if at root and logged in, check for saved route
        if (isLoggedIn && (currentPath == '/' || currentPath == '/dashboard')) {
          if (appProvider.lastRoute != null && appProvider.lastRoute != currentPath) {
            final target = appProvider.lastRoute!;
            debugPrint('GoRouter: [RECOVERY] Found saved route: $target');
            appProvider.clearLastRoute(); // Clear so it only happens once
            return target;
          }
        }
        
        // If logged in and on login page, go to dashboard
        if (isLoggedIn && isLoggingIn) {
          debugPrint('GoRouter: [AUTH GUARD] Already logged in. Redirecting from /login to /dashboard');
          return '/dashboard';
        }

        debugPrint('GoRouter: [AUTH GUARD] Proceeding to $currentPath');
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Error: ${state.error}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isInitialized = provider.isInitialized;

    return MaterialApp.router(
      title: 'OG Manager App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.themeMode,
      locale: Locale(provider.languageCode),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (!isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return child!;
      },
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

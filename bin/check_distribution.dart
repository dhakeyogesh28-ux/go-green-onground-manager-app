import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://hhgxctansltxlrhzunji.supabase.co';
  final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoZ3hjdGFuc2x0eGxyaHp1bmppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5NDM3ODQsImV4cCI6MjA3OTUxOTc4NH0.AbbDe3eCmRGGnCzK4F5ofIvF1NerhFF53M356pWd00E';

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    print('--- TESTING JOIN QUERY ---');
    // Testing join between mobile_activities and crm_vehicles
    final response = await client
        .from('mobile_activities')
        .select('*, crm_vehicles!inner(primary_hub_id)')
        .limit(1);
    
    print('Success! Data: $response');

  } catch (e) {
    print('❌ Error: $e');
    print('\nTrying alternative with filter...');
    try {
      final response = await client
          .from('mobile_activities')
          .select('*')
          .filter('vehicle_id', 'in', '(select vehicle_id from crm_vehicles where primary_hub_id is not null)')
          .limit(1);
      print('Alternative Success! Data: $response');
    } catch (e2) {
      print('❌ Alternative Error: $e2');
    }
  } finally {
    exit(0);
  }
}

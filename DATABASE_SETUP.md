# Mobile App Database Setup

## Overview
This document explains how to set up the database for the mobile app to sync with the admin panel.

## Prerequisites
- Supabase project already set up (same as admin panel)
- Access to Supabase SQL Editor

## Step 1: Run Database Migration

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the contents of `database_migration.sql`
5. Paste into the SQL Editor
6. Click **Run** to execute the migration

This will create the following tables:
- `mobile_daily_inventory` - For daily inventory checks
- `mobile_inventory_photos` - For inventory photo tracking

## Step 2: Verify Tables

After running the migration, verify the tables were created:

1. Go to **Table Editor** in Supabase
2. You should see the new tables listed
3. Check that RLS (Row Level Security) is enabled

## Step 3: Configure Storage (If Not Already Done)

The mobile app uses the same `vehicle-documents` storage bucket as the admin panel.

If you haven't created it yet:

1. Go to **Storage** in Supabase
2. Click **New bucket**
3. Name it: `vehicle-documents`
4. Set to **Public** (or configure RLS policies)
5. Click **Create bucket**

### Storage RLS Policies

If you need to configure storage policies:

1. Go to **Storage** → **Policies**
2. Select `vehicle-documents` bucket
3. Create policies for INSERT and SELECT operations
4. See `admin_pannel/SUPABASE_SETUP.md` for detailed instructions

## Step 4: Test Connection

1. Run the mobile app: `flutter run -d <device>`
2. Check the console for: `✅ Supabase initialized successfully`
3. Log in and verify vehicles are loaded from the database

## Shared Database Tables

The mobile app uses these existing tables from the admin panel:
- `crm_vehicles` - Vehicle data
- `maintenance_job` - Service records and reported issues
- `hub` - Location/hub information
- `charging_session` - Charging data

## Data Synchronization

Changes made in either app will be visible in the other:

- **Admin Panel → Mobile**: Add/edit vehicles in admin panel, they appear in mobile app
- **Mobile → Admin Panel**: Report issues in mobile app, they appear in admin panel's maintenance jobs

## Troubleshooting

### Connection Issues
- Verify Supabase URL and anon key in `lib/config/supabase_config.dart`
- Check that both apps use the same credentials

### No Data Showing
- Pull down to refresh in the mobile app
- Check Supabase Table Editor to verify data exists
- Check console logs for error messages

### Upload Failures
- Verify `vehicle-documents` storage bucket exists
- Check storage RLS policies are configured
- Ensure bucket is set to public or has proper policies

## Offline Support

The mobile app includes offline support:
- Data is cached locally using SharedPreferences
- Operations are queued when offline
- Automatic sync when connection is restored

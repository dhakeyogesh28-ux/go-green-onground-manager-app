-- ============================================
-- FIX: Row-Level Security (RLS) Policies for Mobile App Tables
-- ============================================
-- This script fixes the "Unauthorized" (42501) error when inserting records
-- Run this in your Supabase SQL Editor
-- ============================================

-- 1. FIX FOR mobile_inventory_photos
ALTER TABLE mobile_inventory_photos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon to insert photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow anon to read photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow authenticated users to read photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow authenticated users to insert photos" ON mobile_inventory_photos;

CREATE POLICY "Allow anon to insert photos" ON mobile_inventory_photos FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon to read photos" ON mobile_inventory_photos FOR SELECT TO anon USING (true);
CREATE POLICY "Allow authenticated users to read photos" ON mobile_inventory_photos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert photos" ON mobile_inventory_photos FOR INSERT TO authenticated WITH CHECK (true);

-- 2. FIX FOR mobile_activities
ALTER TABLE mobile_activities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon to insert activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow anon to read activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow authenticated users to read activities" ON mobile_activities;
DROP POLICY IF EXISTS "Allow authenticated users to insert activities" ON mobile_activities;

CREATE POLICY "Allow anon to insert activities" ON mobile_activities FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon to read activities" ON mobile_activities FOR SELECT TO anon USING (true);
CREATE POLICY "Allow authenticated users to read activities" ON mobile_activities FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert activities" ON mobile_activities FOR INSERT TO authenticated WITH CHECK (true);

-- 3. FIX FOR mobile_maintenance_jobs
ALTER TABLE mobile_maintenance_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon to insert maintenance" ON mobile_maintenance_jobs;
DROP POLICY IF EXISTS "Allow anon to read maintenance" ON mobile_maintenance_jobs;
DROP POLICY IF EXISTS "Allow anon to update maintenance" ON mobile_maintenance_jobs;
DROP POLICY IF EXISTS "Allow authenticated users to read maintenance" ON mobile_maintenance_jobs;
DROP POLICY IF EXISTS "Allow authenticated users to insert maintenance" ON mobile_maintenance_jobs;

CREATE POLICY "Allow anon to insert maintenance" ON mobile_maintenance_jobs FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon to read maintenance" ON mobile_maintenance_jobs FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anon to update maintenance" ON mobile_maintenance_jobs FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated users to read maintenance" ON mobile_maintenance_jobs FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert maintenance" ON mobile_maintenance_jobs FOR INSERT TO authenticated WITH CHECK (true);

-- 4. FIX FOR mobile_daily_inventory
ALTER TABLE mobile_daily_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon to insert inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow anon to read inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow anon to update inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow authenticated users to read inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow authenticated users to insert inventory" ON mobile_daily_inventory;

CREATE POLICY "Allow anon to insert inventory" ON mobile_daily_inventory FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Allow anon to read inventory" ON mobile_daily_inventory FOR SELECT TO anon USING (true);
CREATE POLICY "Allow anon to update inventory" ON mobile_daily_inventory FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated users to read inventory" ON mobile_daily_inventory FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated users to insert inventory" ON mobile_daily_inventory FOR INSERT TO authenticated WITH CHECK (true);

-- 5. VERIFICATION
DO $$ 
BEGIN 
    RAISE NOTICE '✅ RLS policies updated for all mobile tables. Anon and Authenticated roles now have access.';
END $$;

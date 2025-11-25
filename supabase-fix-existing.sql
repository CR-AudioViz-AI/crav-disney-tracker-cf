-- =============================================
-- Disney Deal Tracker - FIX EXISTING TABLES
-- This adds missing columns without dropping data
-- =============================================

-- Fix users table - add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add total_savings if missing
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'total_savings'
    ) THEN
        ALTER TABLE users ADD COLUMN total_savings INTEGER DEFAULT 0;
        RAISE NOTICE '✓ Added total_savings column to users table';
    ELSE
        RAISE NOTICE '✓ total_savings column already exists';
    END IF;

    -- Add alerts_received if missing
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'alerts_received'
    ) THEN
        ALTER TABLE users ADD COLUMN alerts_received INTEGER DEFAULT 0;
        RAISE NOTICE '✓ Added alerts_received column to users table';
    ELSE
        RAISE NOTICE '✓ alerts_received column already exists';
    END IF;
END $$;

-- Recreate the admin_stats view (it's safe to drop and recreate views)
DROP VIEW IF EXISTS admin_stats;
CREATE VIEW admin_stats AS
SELECT 
    (SELECT COUNT(*) FROM price_alerts WHERE is_active = true) as active_alerts,
    (SELECT COUNT(DISTINCT email) FROM price_alerts) as total_users,
    (SELECT COALESCE(SUM(total_savings), 0) FROM users) as total_savings_platform,
    (SELECT COUNT(*) FROM notifications_log WHERE sent_at > NOW() - INTERVAL '24 hours') as alerts_sent_24h,
    (SELECT COUNT(*) FROM analytics_events WHERE created_at > NOW() - INTERVAL '24 hours') as events_24h;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '✅ EXISTING TABLES FIXED!';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE '✓ Missing columns added';
    RAISE NOTICE '✓ admin_stats view recreated';
    RAISE NOTICE '✓ All existing data preserved';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Database is now ready!';
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

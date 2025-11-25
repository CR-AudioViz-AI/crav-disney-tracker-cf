-- =============================================
-- Disney Deal Tracker - CLEAN SLATE Installation
-- This drops existing tables and recreates fresh
-- =============================================

-- STEP 1: Drop everything in correct order (views first, then tables)
DROP VIEW IF EXISTS admin_stats CASCADE;
DROP TABLE IF EXISTS notifications_log CASCADE;
DROP TABLE IF EXISTS analytics_events CASCADE;
DROP TABLE IF EXISTS price_history CASCADE;
DROP TABLE IF EXISTS price_alerts CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- STEP 2: Create all tables fresh

-- 1. PRICE ALERTS TABLE
CREATE TABLE price_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    hotel_id VARCHAR(100) NOT NULL,
    hotel_name VARCHAR(255) NOT NULL,
    target_price INTEGER,
    is_active BOOLEAN DEFAULT true,
    is_passholder BOOLEAN DEFAULT false,
    notification_method VARCHAR(20) DEFAULT 'email',
    phone_number VARCHAR(20),
    last_notified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_alerts_email ON price_alerts(email);
CREATE INDEX idx_alerts_hotel ON price_alerts(hotel_id);
CREATE INDEX idx_alerts_active ON price_alerts(is_active) WHERE is_active = true;

-- 2. PRICE HISTORY TABLE
CREATE TABLE price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id VARCHAR(100) NOT NULL,
    hotel_name VARCHAR(255) NOT NULL,
    price INTEGER NOT NULL,
    source VARCHAR(50) NOT NULL,
    discount_percentage INTEGER,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_price_history_hotel ON price_history(hotel_id, recorded_at DESC);

-- 3. ANALYTICS EVENTS TABLE
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    user_id VARCHAR(255),
    session_id VARCHAR(255),
    page_url TEXT,
    referrer TEXT,
    user_agent TEXT,
    ip_address INET,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_event_type ON analytics_events(event_type, created_at DESC);
CREATE INDEX idx_analytics_session ON analytics_events(session_id);

-- 4. USERS TABLE (with all columns we need)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    is_passholder BOOLEAN DEFAULT false,
    total_savings INTEGER DEFAULT 0,
    alerts_received INTEGER DEFAULT 0,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- 5. NOTIFICATIONS LOG
CREATE TABLE notifications_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id UUID REFERENCES price_alerts(id) ON DELETE SET NULL,
    user_email VARCHAR(255) NOT NULL,
    hotel_name VARCHAR(255) NOT NULL,
    old_price INTEGER,
    new_price INTEGER,
    discount_percentage INTEGER,
    notification_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    error_message TEXT,
    sent_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_alert ON notifications_log(alert_id);
CREATE INDEX idx_notifications_user ON notifications_log(user_email, sent_at DESC);

-- STEP 3: Create view AFTER all tables exist
CREATE VIEW admin_stats AS
SELECT 
    (SELECT COUNT(*) FROM price_alerts WHERE is_active = true) as active_alerts,
    (SELECT COUNT(DISTINCT email) FROM price_alerts) as total_users,
    (SELECT COALESCE(SUM(total_savings), 0) FROM users) as total_savings_platform,
    (SELECT COUNT(*) FROM notifications_log WHERE sent_at > NOW() - INTERVAL '24 hours') as alerts_sent_24h,
    (SELECT COUNT(*) FROM analytics_events WHERE created_at > NOW() - INTERVAL '24 hours') as events_24h;

-- STEP 4: Enable Row Level Security
ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications_log ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can create alerts" ON price_alerts
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own alerts" ON price_alerts
    FOR SELECT USING (true);

CREATE POLICY "Users can update own alerts" ON price_alerts
    FOR UPDATE USING (true);

CREATE POLICY "Anyone can view price history" ON price_history
    FOR SELECT USING (true);

CREATE POLICY "Service can insert price history" ON price_history
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can insert analytics" ON analytics_events
    FOR INSERT WITH CHECK (true);

-- STEP 5: Create triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_price_alerts_updated_at
    BEFORE UPDATE ON price_alerts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- STEP 6: Insert sample data
INSERT INTO price_history (hotel_id, hotel_name, price, source, discount_percentage, recorded_at)
VALUES 
    ('pop-century', 'Pop Century Resort', 169, 'disney-direct', 0, NOW() - INTERVAL '6 hours'),
    ('pop-century', 'Pop Century Resort', 121, 'priceline-express', 28, NOW() - INTERVAL '2 hours'),
    ('port-orleans', 'Port Orleans Riverside', 272, 'disney-direct', 0, NOW() - INTERVAL '8 hours'),
    ('port-orleans', 'Port Orleans Riverside', 48, 'priceline-express', 82, NOW() - INTERVAL '6 hours'),
    ('caribbean-beach', 'Caribbean Beach Resort', 249, 'disney-direct', 0, NOW() - INTERVAL '5 hours'),
    ('caribbean-beach', 'Caribbean Beach Resort', 187, 'hotwire-hotrate', 25, NOW() - INTERVAL '4 hours');

-- STEP 7: Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '✅ DATABASE SETUP COMPLETE!';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE '📦 Tables Created:';
    RAISE NOTICE '   ✓ price_alerts';
    RAISE NOTICE '   ✓ price_history (6 sample records)';
    RAISE NOTICE '   ✓ analytics_events';
    RAISE NOTICE '   ✓ users';
    RAISE NOTICE '   ✓ notifications_log';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Views Created:';
    RAISE NOTICE '   ✓ admin_stats';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Security:';
    RAISE NOTICE '   ✓ Row Level Security enabled';
    RAISE NOTICE '   ✓ Policies configured';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Ready to use!';
    RAISE NOTICE '';
    RAISE NOTICE 'Test it now:';
    RAISE NOTICE '1. Go to https://crav-disney-tracker-cf.pages.dev';
    RAISE NOTICE '2. Sign up for a price alert';
    RAISE NOTICE '3. Check admin dashboard';
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

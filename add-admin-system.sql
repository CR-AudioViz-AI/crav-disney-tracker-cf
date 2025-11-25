-- =============================================
-- Add Admin System - SAFE VERSION
-- Adds all missing columns first
-- =============================================

-- Step 1: Add missing columns to users table if they don't exist
DO $$ 
BEGIN
    -- Add is_passholder column
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'is_passholder'
    ) THEN
        ALTER TABLE users ADD COLUMN is_passholder BOOLEAN DEFAULT false;
        RAISE NOTICE '✓ Added is_passholder column';
    ELSE
        RAISE NOTICE '✓ is_passholder column already exists';
    END IF;

    -- Add is_admin column
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'is_admin'
    ) THEN
        ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT false;
        RAISE NOTICE '✓ Added is_admin column';
    ELSE
        RAISE NOTICE '✓ is_admin column already exists';
    END IF;

    -- Add total_savings column
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'total_savings'
    ) THEN
        ALTER TABLE users ADD COLUMN total_savings INTEGER DEFAULT 0;
        RAISE NOTICE '✓ Added total_savings column';
    ELSE
        RAISE NOTICE '✓ total_savings column already exists';
    END IF;

    -- Add alerts_received column
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'alerts_received'
    ) THEN
        ALTER TABLE users ADD COLUMN alerts_received INTEGER DEFAULT 0;
        RAISE NOTICE '✓ Added alerts_received column';
    ELSE
        RAISE NOTICE '✓ alerts_received column already exists';
    END IF;
END $$;

-- Step 2: Insert or update Roy and Cindy as admins
INSERT INTO users (email, is_admin, is_passholder, created_at, updated_at)
VALUES 
    ('royhenderson@craudiovizai.com', true, true, NOW(), NOW()),
    ('cindyhenderson@craudiovizai.com', true, true, NOW(), NOW())
ON CONFLICT (email) 
DO UPDATE SET 
    is_admin = true,
    is_passholder = true,
    updated_at = NOW();

-- Step 3: Success message
DO $$
DECLARE
    roy_exists BOOLEAN;
    cindy_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM users WHERE email = 'royhenderson@craudiovizai.com' AND is_admin = true) INTO roy_exists;
    SELECT EXISTS(SELECT 1 FROM users WHERE email = 'cindyhenderson@craudiovizai.com' AND is_admin = true) INTO cindy_exists;
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '✅ ADMIN SYSTEM ACTIVATED';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE '👑 Admin Users:';
    IF roy_exists THEN
        RAISE NOTICE '   ✓ royhenderson@craudiovizai.com';
    END IF;
    IF cindy_exists THEN
        RAISE NOTICE '   ✓ cindyhenderson@craudiovizai.com';
    END IF;
    RAISE NOTICE '';
    RAISE NOTICE '🎁 Admin Benefits:';
    RAISE NOTICE '   • Unlimited price alerts';
    RAISE NOTICE '   • Free forever (no payment required)';
    RAISE NOTICE '   • Priority support';
    RAISE NOTICE '   • All Pro features';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Test it now:';
    RAISE NOTICE '   1. Go to https://crav-disney-tracker-cf.pages.dev';
    RAISE NOTICE '   2. Sign up with your admin email';
    RAISE NOTICE '   3. See "👑 Admin Access Activated!" message';
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

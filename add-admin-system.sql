-- =============================================
-- Add Admin System to Database
-- =============================================

-- Add is_admin column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- Set Roy and Cindy as admins
UPDATE users 
SET is_admin = true 
WHERE email IN ('royhenderson@craudiovizai.com', 'cindyhenderson@craudiovizai.com');

-- Insert Roy and Cindy if they don't exist yet
INSERT INTO users (email, is_admin, is_passholder, created_at)
VALUES 
    ('royhenderson@craudiovizai.com', true, true, NOW()),
    ('cindyhenderson@craudiovizai.com', true, true, NOW())
ON CONFLICT (email) 
DO UPDATE SET 
    is_admin = true,
    is_passholder = true,
    updated_at = NOW();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '✅ ADMIN SYSTEM ACTIVATED';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE '👑 Admins with unlimited access:';
    RAISE NOTICE '   • royhenderson@craudiovizai.com';
    RAISE NOTICE '   • cindyhenderson@craudiovizai.com';
    RAISE NOTICE '';
    RAISE NOTICE '✓ Unlimited price alerts';
    RAISE NOTICE '✓ Free forever';
    RAISE NOTICE '✓ Priority support';
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

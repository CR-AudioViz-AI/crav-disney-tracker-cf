// =============================================
// Alert Signup Function - Cloudflare Pages
// Handles email/SMS alert registration
// =============================================

export async function onRequest(context) {
  const SUPABASE_URL = 'https://kteobfyferrukqeolofj.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0ZW9iZnlmZXJydWtxZW9sb2ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxOTcyNjYsImV4cCI6MjA3NzU1NzI2Nn0.uy-jlF_z6qVb8qogsNyGDLHqT4HhmdRhLrW7zPv3qhY';

  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  // Handle preflight
  if (context.request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  // Only allow POST
  if (context.request.method !== 'POST') {
    return new Response(JSON.stringify({ 
      success: false, 
      error: 'Method not allowed' 
    }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }

  try {
    // Parse request body
    const body = await context.request.json();
    const { email, hotel_id, hotel_name, target_price, is_passholder, phone_number } = body;

    // Validation
    if (!email || !hotel_id) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Email and hotel selection required' 
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Invalid email address' 
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check if alert already exists
    const checkResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/price_alerts?email=eq.${encodeURIComponent(email)}&hotel_id=eq.${hotel_id}&is_active=eq.true`,
      {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const existingAlerts = await checkResponse.json();

    if (existingAlerts && existingAlerts.length > 0) {
      return new Response(JSON.stringify({ 
        success: true,
        message: 'You already have an alert for this hotel',
        alert_id: existingAlerts[0].id
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Create new alert
    const alertData = {
      email: email.toLowerCase().trim(),
      hotel_id,
      hotel_name: hotel_name || getHotelName(hotel_id),
      target_price: target_price || null,
      is_passholder: is_passholder || false,
      notification_method: phone_number ? 'sms' : 'email',
      phone_number: phone_number || null,
      is_active: true
    };

    const insertResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/price_alerts`,
      {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify(alertData)
      }
    );

    if (!insertResponse.ok) {
      const error = await insertResponse.text();
      throw new Error(`Failed to create alert: ${error}`);
    }

    const newAlert = await insertResponse.json();

    // Create or update user record
    await upsertUser(email, is_passholder, SUPABASE_URL, SUPABASE_ANON_KEY);

    // Track analytics event
    await trackEvent({
      event_type: 'alert_created',
      event_data: { hotel_id, is_passholder },
      user_id: email,
      page_url: context.request.url
    }, SUPABASE_URL, SUPABASE_ANON_KEY);

    // TODO: Send welcome email via Resend or SendGrid
    // await sendWelcomeEmail(email, hotel_name);

    return new Response(JSON.stringify({ 
      success: true,
      message: 'Alert created successfully! We\'ll notify you when prices drop.',
      alert_id: newAlert[0].id,
      hotel_name: alertData.hotel_name
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Alert signup error:', error);
    
    return new Response(JSON.stringify({ 
      success: false, 
      error: 'Failed to create alert. Please try again.',
      details: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}

// Helper: Get hotel name from ID
function getHotelName(hotelId) {
  const hotelNames = {
    'grand-floridian': 'Grand Floridian Resort & Spa',
    'polynesian': 'Polynesian Village Resort',
    'contemporary': 'Contemporary Resort',
    'beach-club': 'Beach Club Resort',
    'yacht-club': 'Yacht Club Resort',
    'boardwalk': 'BoardWalk Inn',
    'wilderness-lodge': 'Wilderness Lodge',
    'animal-kingdom-lodge': 'Animal Kingdom Lodge',
    'riviera': 'Riviera Resort',
    'caribbean-beach': 'Caribbean Beach Resort',
    'coronado': 'Coronado Springs Resort',
    'port-orleans-riverside': 'Port Orleans Riverside',
    'port-orleans-french': 'Port Orleans French Quarter',
    'pop-century': 'Pop Century Resort',
    'art-animation': 'Art of Animation Resort',
    'all-star-movies': 'All-Star Movies Resort',
    'all-star-music': 'All-Star Music Resort',
    'all-star-sports': 'All-Star Sports Resort'
  };
  return hotelNames[hotelId] || 'Disney Resort';
}

// Helper: Upsert user
async function upsertUser(email, isPassholder, supabaseUrl, apiKey) {
  try {
    await fetch(`${supabaseUrl}/rest/v1/users`, {
      method: 'POST',
      headers: {
        'apikey': apiKey,
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates'
      },
      body: JSON.stringify({
        email: email.toLowerCase().trim(),
        is_passholder: isPassholder,
        last_login_at: new Date().toISOString()
      })
    });
  } catch (error) {
    console.error('Error upserting user:', error);
  }
}

// Helper: Track analytics event
async function trackEvent(eventData, supabaseUrl, apiKey) {
  try {
    await fetch(`${supabaseUrl}/rest/v1/analytics_events`, {
      method: 'POST',
      headers: {
        'apikey': apiKey,
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        ...eventData,
        created_at: new Date().toISOString()
      })
    });
  } catch (error) {
    console.error('Error tracking event:', error);
  }
}

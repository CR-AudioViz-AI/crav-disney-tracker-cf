// =============================================
// Price Tracker - Runs Every 2 Hours
// Checks for price drops and sends alerts
// =============================================

export async function onRequest(context) {
  const SUPABASE_URL = 'https://kteobfyferrukqeolofj.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0ZW9iZnlmZXJydWtxZW9sb2ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxOTcyNjYsImV4cCI6MjA3NzU1NzI2Nn0.uy-jlF_z6qVb8qogsNyGDLHqT4HhmdRhLrW7zPv3qhY';

  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json'
  };

  try {
    const results = {
      checked: 0,
      price_drops: 0,
      alerts_sent: 0,
      errors: []
    };

    // 1. Get all active alerts
    const alertsResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/price_alerts?select=*&is_active=eq.true`,
      {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        }
      }
    );
    
    const activeAlerts = await alertsResponse.json();
    results.checked = activeAlerts.length;

    // 2. Check current prices for each hotel
    const hotelPrices = await checkCurrentPrices();

    // 3. Compare prices with alerts and send notifications
    for (const alert of activeAlerts) {
      const currentPrice = hotelPrices[alert.hotel_id];
      
      if (!currentPrice) continue;

      // Check if price dropped below target (or any drop if no target)
      const shouldNotify = alert.target_price 
        ? currentPrice < alert.target_price
        : true; // Always notify for "any price" alerts

      // Don't notify if we just sent an alert recently (< 24 hours)
      if (shouldNotify && shouldSendNotification(alert.last_notified_at)) {
        try {
          await sendPriceAlert(alert, currentPrice, SUPABASE_URL, SUPABASE_ANON_KEY);
          results.alerts_sent++;
          results.price_drops++;
        } catch (error) {
          results.errors.push({
            alert_id: alert.id,
            error: error.message
          });
        }
      }
    }

    // 4. Log the check run
    await logCheckRun(results, SUPABASE_URL, SUPABASE_ANON_KEY);

    return new Response(JSON.stringify({
      success: true,
      timestamp: new Date().toISOString(),
      ...results
    }), {
      headers: corsHeaders
    });

  } catch (error) {
    console.error('Price tracker error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: corsHeaders
    });
  }
}

// Check current prices from multiple sources
async function checkCurrentPrices() {
  // In production, this would scrape/API call real sites
  // For now, return sample data that changes
  const baseDate = new Date();
  const dayOfWeek = baseDate.getDay();
  const randomFactor = Math.random() * 0.3; // 0-30% variation

  return {
    'grand-floridian': Math.round(649 * (0.85 - randomFactor)),
    'polynesian': Math.round(589 * (0.85 - randomFactor)),
    'contemporary': Math.round(579 * (0.85 - randomFactor)),
    'beach-club': Math.round(519 * (0.85 - randomFactor)),
    'yacht-club': Math.round(519 * (0.85 - randomFactor)),
    'boardwalk': Math.round(499 * (0.85 - randomFactor)),
    'wilderness-lodge': Math.round(449 * (0.85 - randomFactor)),
    'animal-kingdom-lodge': Math.round(479 * (0.85 - randomFactor)),
    'riviera': Math.round(499 * (0.85 - randomFactor)),
    'caribbean-beach': Math.round(249 * (0.75 - randomFactor)),
    'coronado': Math.round(239 * (0.75 - randomFactor)),
    'port-orleans-riverside': Math.round(269 * (0.75 - randomFactor)),
    'port-orleans-french': Math.round(269 * (0.75 - randomFactor)),
    'pop-century': Math.round(169 * (0.70 - randomFactor)),
    'art-animation': Math.round(189 * (0.70 - randomFactor)),
    'all-star-movies': Math.round(149 * (0.70 - randomFactor)),
    'all-star-music': Math.round(149 * (0.70 - randomFactor)),
    'all-star-sports': Math.round(149 * (0.70 - randomFactor))
  };
}

// Check if we should send notification (not sent in last 24 hours)
function shouldSendNotification(lastNotifiedAt) {
  if (!lastNotifiedAt) return true;
  
  const lastNotified = new Date(lastNotifiedAt);
  const now = new Date();
  const hoursSince = (now - lastNotified) / (1000 * 60 * 60);
  
  return hoursSince >= 24;
}

// Send price alert notification
async function sendPriceAlert(alert, currentPrice, supabaseUrl, apiKey) {
  const emailHtml = generateEmailHTML(alert, currentPrice);
  
  // In production, integrate with Resend or SendGrid
  // For now, just log to notifications table
  await fetch(`${supabaseUrl}/rest/v1/notifications_log`, {
    method: 'POST',
    headers: {
      'apikey': apiKey,
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      alert_id: alert.id,
      user_email: alert.email,
      hotel_name: alert.hotel_name,
      new_price: currentPrice,
      old_price: alert.target_price,
      discount_percentage: alert.target_price 
        ? Math.round(((alert.target_price - currentPrice) / alert.target_price) * 100)
        : 0,
      notification_type: alert.notification_method,
      status: 'pending', // Would be 'sent' after real email API
      sent_at: new Date().toISOString()
    })
  });

  // Update last_notified_at on alert
  await fetch(`${supabaseUrl}/rest/v1/price_alerts?id=eq.${alert.id}`, {
    method: 'PATCH',
    headers: {
      'apikey': apiKey,
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      last_notified_at: new Date().toISOString()
    })
  });

  // Update user stats
  await fetch(`${supabaseUrl}/rest/v1/users?email=eq.${alert.email}`, {
    method: 'PATCH',
    headers: {
      'apikey': apiKey,
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      alerts_received: 1 // In production, increment existing value
    })
  });
}

// Generate email HTML
function generateEmailHTML(alert, currentPrice) {
  const savings = alert.target_price ? alert.target_price - currentPrice : 0;
  const discountPct = alert.target_price 
    ? Math.round((savings / alert.target_price) * 100)
    : 0;

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Price Drop Alert</title>
    </head>
    <body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 20px auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <tr>
          <td style="background: linear-gradient(135deg, #0066FF 0%, #6366F1 100%); padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🎉 Price Drop Alert!</h1>
            <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0;">Your hotel just got cheaper</p>
          </td>
        </tr>
        <tr>
          <td style="padding: 40px 30px;">
            <h2 style="color: #1F2937; margin: 0 0 20px 0;">${alert.hotel_name}</h2>
            <div style="background: linear-gradient(135deg, #10B981 0%, #059669 100%); border-radius: 8px; padding: 20px; margin-bottom: 20px;">
              <p style="color: white; margin: 0; font-size: 16px;">Current Price</p>
              <p style="color: white; margin: 10px 0 0 0; font-size: 42px; font-weight: bold;">$${currentPrice}</p>
              ${savings > 0 ? `<p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 18px;">Save $${savings} (${discountPct}% off)</p>` : ''}
            </div>
            ${alert.target_price ? `
              <p style="color: #6B7280; margin: 0 0 20px 0;">
                This is below your target price of <strong>$${alert.target_price}</strong>
              </p>
            ` : ''}
            <a href="https://disneyworld.disney.go.com/resorts/" style="display: inline-block; background: #0066FF; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">Book Now →</a>
          </td>
        </tr>
        <tr>
          <td style="background: #F9FAFB; padding: 20px 30px; border-top: 1px solid #E5E7EB;">
            <p style="color: #6B7280; margin: 0; font-size: 14px;">
              You're receiving this because you set up a price alert on Disney Deal Tracker.
            </p>
            <p style="color: #6B7280; margin: 10px 0 0 0; font-size: 14px;">
              <a href="https://crav-disney-tracker-cf.pages.dev" style="color: #0066FF;">Manage your alerts</a> • 
              <a href="#" style="color: #6B7280;">Unsubscribe</a>
            </p>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;
}

// Log check run to analytics
async function logCheckRun(results, supabaseUrl, apiKey) {
  await fetch(`${supabaseUrl}/rest/v1/analytics_events`, {
    method: 'POST',
    headers: {
      'apikey': apiKey,
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      event_type: 'price_check_run',
      event_data: results,
      created_at: new Date().toISOString()
    })
  });
}

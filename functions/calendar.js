export async function onRequest(context) {
  const SUPABASE_URL = 'https://kteobfyferrukqeolofj.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0ZW9iZnlmZXJydWtxZW9sb2ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk2MjMxMDcsImV4cCI6MjA0NTE5OTEwN30.xK0YOdLjSLMnH-p91Q-WkSIDN_fZnHgwU46T9_l2lM8';

  try {
    const today = new Date().toISOString().split('T')[0];
    const response = await fetch(`${SUPABASE_URL}/rest/v1/deal_calendar_cache?cache_date=gte.${today}&order=cache_date.asc&limit=30`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
      }
    });

    const calendarData = await response.json();

    return new Response(JSON.stringify({
      success: true,
      database: 'connected',
      calendarData: calendarData,
      daysWithDeals: calendarData.filter(d => d.deal_count > 0).length,
      message: 'Calendar system connected to database',
      timestamp: new Date().toISOString()
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}

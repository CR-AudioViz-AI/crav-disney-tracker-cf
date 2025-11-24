export async function onRequest(context) {
  const SUPABASE_URL = 'https://kteobfyferrukqeolofj.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0ZW9iZnlmZXJydWtxZW9sb2ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk2MjMxMDcsImV4cCI6MjA0NTE5OTEwN30.xK0YOdLjSLMnH-p91Q-WkSIDN_fZnHgwU46T9_l2lM8';

  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/deals?select=*,resort:resorts(name,resort_type,location)&is_active=eq.true&order=discount_percentage.desc.nullslast&limit=10`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    const deals = await response.json();

    return new Response(JSON.stringify({
      success: true,
      deals: deals,
      count: deals.length,
      message: deals.length > 0 ? 'Active deals found' : 'Database connected - ready for aggregators',
      database: 'connected',
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
      deals: [],
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

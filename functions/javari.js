export async function onRequest(context) {
  const SUPABASE_URL = 'https://kteobfyferrukqeolofj.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0ZW9iZnlmZXJydWtxZW9sb2ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk2MjMxMDcsImV4cCI6MjA0NTE5OTEwN30.xK0YOdLjSLMnH-p91Q-WkSIDN_fZnHgwU46T9_l2lM8';

  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/javari_learning?select=*`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
      }
    });

    const patterns = await response.json();
    const avgConfidence = patterns.length > 0 
      ? patterns.reduce((sum, p) => sum + (parseFloat(p.confidence_score) || 0), 0) / patterns.length 
      : 0;

    return new Response(JSON.stringify({
      status: 'active',
      message: 'Javari AI - Connected to learning database',
      database: 'connected',
      patternsDiscovered: patterns.length,
      averageConfidence: Math.round(avgConfidence * 100) / 100,
      learningPhase: patterns.length > 10 ? 'learning' : 'observation',
      timestamp: new Date().toISOString()
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      status: 'error',
      message: error.message,
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

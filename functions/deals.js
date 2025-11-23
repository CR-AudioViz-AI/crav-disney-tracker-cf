export async function onRequest(context) {
  return new Response(JSON.stringify({
    deals: [],
    message: 'Deal aggregators coming in Phase 2',
    status: 'mvp',
    timestamp: new Date().toISOString()
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

export async function onRequest(context) {
  return new Response(JSON.stringify({
    calendarData: [],
    message: 'Calendar system ready, deals coming in Phase 2',
    status: 'mvp',
    timestamp: new Date().toISOString()
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

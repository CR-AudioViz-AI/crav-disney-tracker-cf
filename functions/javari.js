export async function onRequest(context) {
  return new Response(JSON.stringify({
    status: 'ready',
    message: 'Javari AI - Autonomous Disney Deal Assistant',
    learningPhase: 'observation',
    accuracy: 0,
    patternsDiscovered: 0,
    version: 'mvp-1.0',
    timestamp: new Date().toISOString()
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

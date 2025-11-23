# Disney Deal Tracker - Cloudflare MVP

Simpler stack deployment:
- **Frontend**: Cloudflare Pages (static HTML)
- **API**: Cloudflare Functions
- **Database**: Supabase
- **Deployed**: Autonomously via API

## Structure
```
public/          - Static files
  index.html     - Main page
functions/       - API endpoints
  deals.js       - Deals API
  javari.js      - Javari AI API
  calendar.js    - Calendar API
```

## Deploy
This deploys automatically via GitHub Actions to Cloudflare Pages.

Phase 2 will add Supabase Edge Functions for deal aggregators.

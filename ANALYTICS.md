# Analytics Plan

MacVitals uses a privacy-first analytics approach.

## Website Analytics

The website is prepared for the free Cloudflare Web Analytics snippet.

Files:

- `docs/analytics-config.js`
- `docs/analytics.js`
- `docs/index.html`
- `docs/privacy.html`
- `docs/support.html`

To enable Cloudflare Web Analytics:

1. Open Cloudflare Dashboard.
2. Go to Analytics & Logs > Web Analytics.
3. Add the MacVitals site.
4. Copy the generated Web Analytics token.
5. Paste the token into `docs/analytics-config.js`.

```js
window.MACVITALS_ANALYTICS = {
  provider: "cloudflare",
  cloudflareToken: "PASTE_TOKEN_HERE"
};
```

Leave `cloudflareToken` blank to disable third-party website analytics.

## Website Events

The website marks these aggregate click events:

- `View on GitHub`
- `Join TestFlight`
- `Privacy Policy`
- `Support`

Events are attached with:

```html
data-analytics-event="Join TestFlight"
```

`docs/analytics.js` records these events in `window.macVitalsAnalyticsEvents` during the page session. If Cloudflare Zaraz or GA4 is added later, the same helper will forward events through `zaraz.track(...)` or `gtag(...)`.

Cloudflare Web Analytics itself is best for page traffic, referrers, countries, devices, and paths. Exact custom click-event reporting needs a free event-capable layer such as Cloudflare Zaraz, GA4, or a self-hosted tool.

## App Analytics

The Mac app does not include third-party analytics in the MVP.

After App Store release, use App Store Connect for:

- Downloads
- Product page views
- Conversion rate
- Source type
- Territory
- Active devices
- Sessions
- Retention
- Crashes

## Privacy Boundary

Do not send these from the app:

- Process names
- Per-app memory readings
- Diagnostic snapshots
- File paths
- Device serial numbers
- User identifiers
- IP addresses

If opt-in app analytics are added later, keep them anonymous, minimal, and clearly disclosed.

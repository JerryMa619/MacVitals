# Analytics Plan

MacVitals uses a privacy-first analytics approach.

## Website Analytics

The website uses Plausible Analytics through:

- `docs/index.html`
- `docs/privacy.html`
- `docs/support.html`
- `docs/analytics.js`

Current Plausible domain value:

```html
data-domain="jerryma619.github.io"
```

If MacVitals moves to a custom domain, update this value on all website pages to the new domain.

## Website Events

The website tracks these aggregate click events:

- `View on GitHub`
- `Join TestFlight`
- `Privacy Policy`
- `Support`

Events are attached with:

```html
data-analytics-event="Join TestFlight"
```

The small `docs/analytics.js` helper sends the event to Plausible when a matching link or button is clicked.

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

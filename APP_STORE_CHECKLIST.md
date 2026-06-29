# App Store Checklist

## Product Claims

- Describe MacVitals as a monitor and diagnostic assistant.
- Avoid claims like "deep clean", "boost instantly", or guaranteed speed improvements.
- Show measured values transparently and explain recommendations.

## Technical Rules

- Use public macOS APIs only.
- Enable App Sandbox before submission.
- Keep Launch at Login on Apple's public ServiceManagement API.
- Keep resource alerts local with `UserNotifications`; do not upload diagnostic data.
- Test process memory visibility while sandboxed.
- Keep network access disabled unless a future feature truly needs it.
- Do not kill processes automatically.
- Do not delete user files or caches without explicit, narrow user consent.

## Privacy

- No analytics in the MVP.
- No account system.
- No data upload.
- Keep diagnostics local; snapshot export is user-triggered and copies plain text to the clipboard.

## Review Notes

- Include a short reviewer note explaining that the app monitors system resource pressure and opens Activity Monitor for user-controlled remediation.
- If process stats are limited under sandboxing, degrade gracefully and keep the dashboard functional.

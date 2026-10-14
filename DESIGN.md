# EcoPin mobile design contract

Updated: 14 October 2026

This replaces the obsolete neon design. The civic identity follows [the web contract](../ecopin-web/DESIGN.md), adapted to citizens reporting concerns and SWMO staff working on phones. The shared backlog defines implementation scope; this document does not claim every screen has been modernized.

## Palette and themes

Use semantic tokens from `lib/core/theme/colors.dart` and `Theme.of(context).colorScheme`. Both themes are supported equally. Primary filled actions use #0052CC with white content; readable blue links use #0052CC in light mode and #82B6FF in dark mode. Environmental accents use #27754D / #83CBA0, sparingly. Environmental branding must not replace lifecycle colors.

| Role | Light | Dark |
| --- | --- | --- |
| Background | #FFFFFF | #121212 |
| Surface | #FFFFFF | #1C1C1C |
| Quiet surface | #F5F7FA | #242424 |
| Main text | #17212E | #F5F5F5 |
| Secondary text | #59636E | #B0B0B0 |
| Divider | #E5E9EE | #333333 |

Success, warning, error, and information keep their semantic meaning. Always accompany colors with written states. Verify contrast after overlays/opacity; target 4.5:1 for ordinary text and 3:1 for large text and essential control boundaries. Do not introduce lime accents or permanently dark screens. Use existing map providers and attribution; this redesign requires no API keys or environment changes.

## Typography, spacing, and shape

Use bundled Outfit. Body 16, secondary body 14, labels 14, captions at least 12 logical pixels. Headings 20–32 for working screens; large promotional typography belongs only on the introduction. Technical payloads may use monospace; navigation and operational labels may not. Long names, addresses, badges, and actions wrap. Support system text scaling without shrinking text to fit.

Every shared typography definition explicitly carries the Outfit family. Setting only `ThemeData.fontFamily` does not cover styles supplied directly to native chips, buttons, and dialogs. Selected choice-chip labels use the foreground associated with their selected container; normal and selected labels must both remain readable in either theme.

Use the existing 4/8/16/24/32/48/64 spacing scale, adding 12 or 20 only for compact groups. Retain established shape tokens: pill buttons/chips, 16 inputs, 24 cards/dialogs. Use thin dividers and quiet elevation only for floating elements. Do not place every data point in an equally prominent card.

## Controls and navigation

- Target at least 48dp interactive areas. A button's configured height is its minimum; it grows for multiline/scaled labels. Named loading states disable duplicate actions.
- Inputs have labels, helper/error text, keyboard/autofill appropriate to their value, visible focus, and named show/hide-password actions. Preserve controllers, validation, submissions, and values after failures.
- Shells keep role destinations, safe areas, readable selected labels, accessible notification counts, and predictable back behavior. Public reporting, My reports, crew objectives, and officer review remain distinct tasks.
- Use the shared native navigation bar for the four role shells. Five-tab shells use Home rather than a long Overview label. Officer secondary destinations belong in the scrollable More sheet. Keep crew detail-route navigation behavior intact. Native navigation labels and supplementary badges follow platform text-scale limits; speak the full unread count. Main content and actions continue to grow with system text size.
- The citizen Report a concern action uses a bounded, wrapping shared button above the navigation bar. Do not apply a circular floating-action shape to a text action. Map status overlays reserve additional space as text size grows. Account avatars use private-media delivery, including fallbacks.
- Forms use logical sections with inline errors and an explicit final review where supported. Keep map attribution and action buttons clear of keyboard and device insets.
- Dialogs/sheets have a clear title, dismiss/back behavior, scrollable content, and usable actions at large text sizes. Continuous motion has pause controls. Respect reduced motion outside the approved web landing behavior.

## States, reports, and field work

Loading, refreshing, empty, failure, unavailable, permission denied, and stale data are different states. Keep existing data visible on refresh. Offer only working recovery actions. Do not present failed loading as an empty list.

Separate validation (review decision) from response lifecycle, priority, assignment, and synchronization. Human-readable display labels may normalize underscores and case; never alter values sent to the backend. Reported, queued locally, uploading, synced, and completed on the server are different outcomes.

Explain actual network policy and pending work. Offline copy must not promise every change is saved or automatically synced. Keep recoverable drafts, queues, authorized lifecycle actions, and the informational conflict model intact. Hide or honestly disable unfinished actions.

Present report location, description, evidence, review state, response progress, consent/agency instructions, and permitted next action in a clear hierarchy. Before/after evidence identifies its provenance. Secure media still uses authenticated delivery; unavailable photos show a truthful fallback. Fullscreen inspection uses contain-fit imagery, labeled navigation, zoom where supported, and captions. Editorial photos and category illustrations are never evidence for an incident.

The reporting form keeps a named location → details → media → review progression. Without a detected location, require explicit map selection before continuing; a default Pasig view is not a detected location. Show an address with coordinates when available and a working address retry when unavailable. Keep entered values after rejection and distinguish a report saved on this device from a server acknowledgement.

Media selection has a visible checking state, repeat-action lock, persistent recoverable errors, and a device-settings action for denied access. Keep photo count/combined-size and video format/duration limits visible. Read actual video duration through the existing player's initialized metadata; never infer duration from file size or truncate it before validation. Selected local photos support uncropped zoom and previous/next navigation; video inspection has explicit play/pause, position, and retry. Identify both as unsent media. Do not autoplay. Controllers are released after inspection/metadata reads. See [Flutter's video-player lifecycle guidance](https://docs.flutter.dev/cookbook/plugins/play-video).

Account forms use a bounded scrollable layout above the keyboard with appropriate autofill, visible password rules, inline validation, and retained values on failure. Email verification identifies the destination email and uses server-provided resend cooldown; a timer never proves verification. Feedback names all five choices, explains that submitting closes the report, and returns to that report after success.

Login and registration send passwords and confirmation exactly as entered, including spaces. Trim email addresses independently; never silently normalize the password. Preserve the existing server requirements and confirmation checks.

Required password updates stay outside the authenticated workspace. Honor the existing login `requirePasswordChange` signal, load the configured password policy, use named new-password autofill and visibility controls, and retain entries after rejection. Hold the pending token only in memory for the existing update endpoint; never persist it as a session or refresh another account's session for that request. Disable duplicate submission and back navigation while an update is in flight. After success, clear the temporary password and return to ordinary sign-in with a clear result. Obtain a fresh session through normal login, since [Supabase sessions can terminate after a password change](https://supabase.com/docs/guides/auth/sessions). Policy failures offer reload; expired or forbidden requests offer sign-in recovery.

Notifications expose All/Unread choices, actual counts, written read state, and local date groups. Unavailable timestamps stay unavailable. Keep controls and feedback in the same scrollable surface so short screens and enlarged text can reach every action. Use the readable dark blue for unread text, a quiet unread tint, and the shared divider color for read-card boundaries. Actions live in a named native menu rather than requiring a swipe. Confirm removal, lock repeat requests, announce outcomes, and show success only after a returned server record/count. Preserve loaded updates during stream interruptions with a stale-data notice and a working reload action. Scope reads and writes to the signed-in user; rebuild notification streams when authentication changes and preserve existing RLS.

Notification report links use the current role's existing route and encoded report ID. A read-mark failure does not prevent opening an otherwise available report; keep its failure feedback when the user returns. Administrators have no report-detail destination in the native scope. Current assignment notifications have no task ID, so do not infer one from their text or fabricate a task link. Operating-system delivery and real-device deep-link behavior require separate device acceptance.

Administrator mobile scope includes the web admin actions supported by the existing backend, as approved on 14 October 2026. Use the existing authenticated API client and allowlisted roles/settings. Keep current-account restrictions and server authorization authoritative; confirm destructive actions and require an explicit password for account creation/reset. Do not log credentials or persist new admin data. Show unavailable summaries honestly, keep useful data visible during refresh, and route session/access recovery to Account. Fleet/algorithm configuration remains web-only unless separately implemented and supported.

Register the approved administration pages inside their own native shell: overview, users, settings, audit logs, account, and notifications. Only an authenticated administrator may enter those routes. Administrator sign-in/splash returns to the administration home; citizen, officer, field crew, and signed-out accounts cannot enter it. Server authorization remains authoritative for every account/settings action.

Account management uses server search/role filters and explicit server pagination; ignore older responses after a newer query. Keep full account details and identifiable copy actions. Current-account role/deletion restrictions follow the backend. Show review and confirmation separately from actual saving; a waiting confirmation is not an uploading/saving state. Use the loaded password policy, retain fields after failure, and keep passwords out of review dialogs. Complete required-change sign-in handling before declaring created/reset account journeys verified.

Audit search identifies its loaded-page scope. Server filters belong in a native disclosure panel, with an explicit Apply action; refreshing does not submit unapplied drafts. Exact action codes are accepted beyond suggestions derived from retrieved entries. Date ranges cover full local days and send UTC bounds. Show compact local UTC offsets rather than long OS timezone names. Full IDs and payloads remain selectable with named copy controls; hide known credential fields recursively in displayed/copied structured payloads. Technical typography prefers the platform monospace face and includes readable fallbacks. Disabled shared actions use readable quiet surfaces and secondary text rather than faded white labels on pale blue.

Charts show question, period, units, readable legends, and useful text summaries from real data. Do not manufacture counts or promote placeholder administrator screens into fake dashboards. Field crews are SWMO personnel.

## Boundaries and verification

Preserve authentication, role access, API contracts, Supabase behavior, backend lifecycle, geolocation precision, private media, consent, and sync. Do not add unsupported exports, saved reports, admin capabilities, or field-crew web access. Dependencies remain visible in [UI_UPDATE_BACKLOG.md](../UI_UPDATE_BACKLOG.md).

Validate narrow/ordinary phones, landscape/tablet where supported, keyboard, safe areas, large text, both themes, long content, no photos, empty/error/refresh, and denied permissions. Crew checks include offline/queued/partial failure/server acknowledgement. Run targeted widget tests and analysis during batches; run broader tests and representative device previews before completion. Record what was actually verified in the backlog.

# EcoPin mobile design contract

Updated: 21 October 2026

This replaces the obsolete neon design. The civic identity follows [the web contract](../ecopin-web/DESIGN.md), adapted to citizens reporting concerns and SWMO staff working on phones. The shared backlog defines implementation scope; this document does not claim every screen has been modernized.

## App purpose and information architecture

Design for a phone held in one hand: find a concern, report it with location and evidence, then follow its progress. Use native Flutter controls and device safe areas rather than reproducing the web header, hero, hover interactions, or desktop sidebar. Keep the current role routes and platform back behavior.

| Citizen control | Job | Existing destination |
| --- | --- | --- |
| Map | Explore public concerns | `ProtectedAppRoutes.maps` |
| Reports | Follow the citizen's own submissions | `ProtectedAppRoutes.reports` |
| Report | Start a new concern; an action rather than a selected tab | Existing location-prefill flow → `ProtectedAppRoutes.createReport` |
| Alerts | Read notifications and their unread count | `ProtectedAppRoutes.notifications` |
| Profile | Manage the signed-in account | `ProtectedAppRoutes.profile` |

Citizen navigation is the first rollout of the raised-action treatment. Staff shells retain their existing shared navigation. Do not imply that their destinations, permissions, or workflows changed.

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

### Welcome screen

The signed-out introduction leads with **A cleaner Pasig starts with us.** Use a civic-blue field in both themes, a white wordmark, and a single soft-green emphasis on “us.” Set the headline in medium Outfit, with ordinary readable body text and a compact three-step sequence: Snap & pin, Describe, Follow up. Avoid script lettering, gradients, decorative badges, and repeated cards.

The bundled `assets/illustrations/welcome_neighborhood.svg` is an original folded-neighborhood drawing: a river, a footbridge, garden plots, and one leaf pin. It is decorative, excluded from screen-reader output, and does not represent live reports or geographic data. Keep all meaningful copy as native text.

Place **Sign in** and **Create an account** in a quiet, theme-aware bottom section using the shared buttons and existing routes. The map currently requires authentication, so the introduction must not offer an anonymous-map action. Constrain the reading width on tablets; let the whole screen scroll on short displays and with enlarged text. Preserve device safe areas, full text scaling, a semantic heading, and keyboard activation.

Verification: account layout tests cover small phones with 2× text, landscape, tablet, both themes, and the two account destinations. Foundation preview tests render the native welcome screen in both themes. Physical-device safe areas and TalkBack remain device acceptance.

### Shared controls

- Target at least 48dp interactive areas. A button's configured height is its minimum; it grows for multiline/scaled labels. Named loading states disable duplicate actions.
- Inputs have labels, helper/error text, keyboard/autofill appropriate to their value, visible focus, and named show/hide-password actions. Preserve controllers, validation, submissions, and values after failures.
- Shells keep role destinations, safe areas, readable selected labels, accessible notification counts, and predictable back behavior. Public reporting, My reports, crew objectives, and officer review remain distinct tasks.
- Staff shells use the shared native navigation bar. Five-tab shells use Home rather than a long Overview label. Officer secondary destinations belong in the scrollable More sheet. Keep crew detail-route navigation behavior intact. Navigation labels and supplementary badges follow platform text-scale limits; speak the full unread count. Main content and actions continue to grow with system text size.
- Citizen navigation uses the raised circular Report action described below. Map status overlays reserve additional space as text size grows. Account avatars elsewhere use private-media delivery, including fallbacks.
- Forms use logical sections with inline errors and an explicit final review where supported. Keep map attribution and action buttons clear of keyboard and device insets.
- Dialogs/sheets have a clear title, dismiss/back behavior, scrollable content, and usable actions at large text sizes. Continuous motion has pause controls. Respect reduced motion outside the approved web landing behavior.

### Citizen bottom navigation

Use `CitizenNavigationBar` in the citizen shell. The supplied navigation reference informs the compact five-position layout, raised center action, fine selection marker, and lighter labels. Use EcoPin's palette and destinations.

- Order: **Map · Reports · Report · Alerts · Profile**. Four destination indices remain unchanged; reporting never becomes a fifth page or a selected tab.
- Attach the surface to the bottom and both screen edges, with only 12dp top-left and top-right corners. No outer margin, floating pill, bottom corner rounding, or gap below the bar. Paint the surface through the bottom device inset and keep every control above it. The citizen shell extends its body behind the bar so the transparent space beside the raised action reveals the screen rather than a rectangular scaffold background.
- The surface is white in light mode and neutral charcoal in dark mode. Keep the rectangular base shadow-free so it cannot create a gray strip beside the raised action on Reports or Alerts. The center has a 72dp surface-colored circular shoulder around a 56dp circular action, which retains its own quiet elevation. Reserve 104dp plus the device's bottom inset for the whole component, so the raised area remains inside the shell's layout and hit-test bounds.
- The report action uses civic blue `#0052CC` and a white camera icon in both themes. Keep its visible **Report** caption and full accessible name, **Report an environmental concern**. During location lookup, disable repeat activation and announce **Finding location**. Preserve current location failures and manual map-selection recovery.
- Use the Bootstrap font bundled with `icons_plus` for map, document, camera, notification, and person icons. Icons are generally 24dp; the central camera is 26dp. Selection adds a short 16 × 2dp marker above the icon and changes icon/label color. It must also expose the native selected state.
- Labels use bundled Outfit, 12dp, regular (400), with ordinary letter spacing. Use the readable blue token for selected labels, secondary text for inactive labels, and a maximum navigation text scale of 1.3. Main content keeps the system's full scale. Keep at least 48dp tap targets and native keyboard focus/activation.
- Alerts retain the visible capped `99+` badge and full unread count for assistive technology. Loading or failed counts remain identifiable. Profile uses the same icon family as its neighboring destinations.

`icons_plus` 5.0.0 subclasses `IconData`, which is final in the app's installed Flutter SDK. Until the upstream package supports that SDK, the citizen widget declares five constant native `IconData` values using the package's Bootstrap font and matching codepoints. Do not import the incompatible Dart barrel or patch the SDK/package cache. Recheck these bindings when upgrading the icon package.

Verification: `test/ui/role_navigation_test.dart` exercises all role routes, both themes, 320dp width, 2× system text, and a 32dp bottom inset. `test/ui/citizen_navigation_test.dart` covers responsive widths, report activation/loading, keyboard activation, and renders the actual Flutter navigation states for visual review. Real Android GPS, TalkBack, and gesture-navigation acceptance remain device checks.

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

## Public map and place search

Public map pins use written response states and recognizable status icons, with a selected ring and named native 48dp actions. Cluster counts expose the full count to assistive technology; the compact visual count may cap at 999+. Keyboard and semantic activation use the existing clustering package's zoom/spiderfy action. Reduced motion disables that package's transition durations. Keep its algorithm and public viewport limits intact.

The selected report is a stable snapshot while the map refreshes. Its scrollable bottom sheet shows the full title, concern, response status, description, and any approximate-location disclosure. Closing the sheet precedes navigation to the existing report route. Do not fetch a more precise location to enrich a public preview. Map refresh failures retain loaded pins with a stale-data notice and retry. Theme changes update the actual tile layer without resetting the map. Show linked OpenStreetMap and CARTO attribution directly on the map; reserve space beside the controls so links remain usable in landscape and at large text sizes.

Map tools have named search, heatmap, location, and legend actions. Location and privacy actions lock repeat requests and provide persistent recovery after denied access or failed saves. A failed privacy read is not consent. The legacy shared crew preview must not invent routes, travel times, traffic, weather, or crew counts; direct crews to their assigned task for supported work.

Place search keeps one 300ms debounce. Explicit submission/retry flushes that timer, and late responses cannot overwrite a newer query or cleared search. Distinguish service failure from a valid empty result. Keep history after removal/storage failures and expose recovery. Opening a place remains possible if saving its recent-search entry fails; explain that failure after returning to the map. Preserve the existing history key, format, deduplication, and ten-item limit.

Microphone initialization is an explicit opt-in through Use voice search. Opening search does not request speech access. Show listening, denied, unavailable, and stop failures honestly, with a typed-search fallback and device-settings recovery. Rebind and release the speech SDK listeners across openings; manual typing invalidates late voice results. The whole search surface scrolls above the keyboard, with labeled input, clear/back controls, wrapping place names, and named history actions. Synthetic preview tests complement separate Android microphone, GPS, settings, keyboard, and TalkBack acceptance.

## Crew dashboard and assignment hierarchy

The dashboard starts with a short greeting and a native, wrapping Sync Center control, followed by the current task and its primary Open current task button. Secondary route context, loaded-assignment progress, up to three queued tasks, local completion receipts, held work, and preparation follow in that order. Keep the task title and supplied address readable in full. Use written priority and response state; do not rely on a colored dot. Opening details is not starting a task, so the button must describe navigation accurately.

Retain the established in-progress → route order → high/urgent priority → creation-time ordering. Completed/cancelled records and locally held or recorded-complete tasks are not proposed as the next task; their records remain accessible through their sections and the full assignment list. Local receipts describe this device/session and do not prove a server acknowledgement. Do not mutate loaded models while arranging the dashboard. Detail links keep existing routes and encoded IDs. Returning from details refreshes local queue counts without silently refetching and replacing task records.

Progress describes loaded assignments, including any cancelled records in its denominator. It is not a shift or today's performance without a supporting filter. Show the count in written text and the progress indicator's label, leaving its numeric accessibility value to Flutter. Route context shows the supplied stop count and the current task's next recorded sequence when available. Dispatch distance/time estimates do not become live ETA or remaining-work claims. Missing route data is unavailable rather than a completed route. Explicit route refresh reloads the existing route provider; routes, authorization, and routing calculations remain unchanged.

Keep useful assignments and route context during refresh failures, with distinct loading, empty, unavailable, stale, and retry states. An empty assignment list does not prove the crew finished its shift. Cached records remain identified as possible cached data. The crew sync control uses actual queued changes, photos, and removals, plus the current mode and detected network. Include photo-only failures and unknown/stale queue feedback. Never label an unknown queue as synced, or hide a failure after an arbitrary short timer. It remains a named, keyboard-accessible destination to Sync Center rather than a tiny gesture-only chip.

The global citizen/officer/admin offline banner and legacy queue indicator have separate acceptance under A09. Improving the crew control does not claim that those other surfaces expose complete sync state.

## Field-crew preparation and Sync Center

Both screens use the shared theme, 24px cards with quiet borders, readable Outfit labels, 48dp actions, safe areas, and one scrollable content surface. Group related facts within cards. Short facts may share a row at ordinary text sizes; enlarged text and long values stack and wrap. Dates include the year and local time. Connection labels identify the network type without implying that the server is reachable.

Preparation describes assigned record information, evidence metadata, notes, and available route records. Full-size photos, reference lists, and map tiles may still need a connection. A reference-service check is not an offline catalogue download. Show each step's written state, actual cached counts, approximate record-storage estimate, and preparation time. Preserve failed section messages through the final result, including unavailable assigned report groups and linked records not returned by the service. Useful records can remain cached while the package has gaps. An earlier restored receipt does not verify every section or current assignment; identify it and offer an update. Retry must recover from estimation as well as download failure without clearing usable cached work.

Offline preparation is an explicit download separate from queued sync policy. Do not promise that Offline Only disables all device network requests. Enabling it is optional and explicit, and it pauses queued syncing until mode changes. Preserve the existing preference keys, enum values, gate rules, and download endpoints. Confirm preference storage before updating the displayed value; retain the previous setting and expose a recoverable error if saving fails.

Sync Center separates queued changes, photo uploads, and photo removals. Repeatedly failed photos are a subset of queued uploads, not another total. Failed queue reads remain unavailable or explicitly stale rather than showing nothing pending. Explain the selected mode and allowed network, with connection refresh and settings recovery. The existing gate remains authoritative for a commit, including its mobile-data confirmation. Guard repeat requests while checking, confirming, syncing, or resetting retries. Resetting a photo's retry allowance does not mean it uploaded; keep that distinction in feedback.

Last-run information includes changes acknowledged, merged, awaiting retry, and not applied, plus attempted/succeeded/failed photo uploads and removals. Review/conflict flags can overlap those totals; a server acknowledgement does not necessarily close a report. Show actual server outcome messages for merged, contested, and verification-required updates. Keep this summary informational with expandable details and a named 48dp dismiss button. It remains until dismissed, resets for a new completed run, and provides no invented manual conflict-resolution controls. Error and partial-failure feedback persists while the relevant state remains.

UI verification uses simulated services and real provider/widget interactions alongside the existing sync and offline regression suites. Android network changes, storage failures, background uploads, real queued evidence, restart recovery, safe areas, and TalkBack still need separate device acceptance. The UI changes do not alter mutation ordering, conflict decisions, photo-sync algorithms, authorization, or database structure.

## Boundaries and verification

Preserve authentication, role access, API contracts, Supabase behavior, backend lifecycle, geolocation precision, private media, consent, and sync. Do not add unsupported exports, saved reports, admin capabilities, or field-crew web access. Dependencies remain visible in [UI_UPDATE_BACKLOG.md](../UI_UPDATE_BACKLOG.md).

Validate narrow/ordinary phones, landscape/tablet where supported, keyboard, safe areas, large text, both themes, long content, no photos, empty/error/refresh, and denied permissions. Crew checks include offline/queued/partial failure/server acknowledgement. Run targeted widget tests and analysis during batches; run broader tests and representative device previews before completion. Record what was actually verified in the backlog.

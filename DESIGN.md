# EcoPin mobile design contract

Updated: 31 October 2026

This replaces the obsolete neon design. The civic identity follows [the web contract](../ecopin-web/DESIGN.md), adapted to citizens reporting concerns and SWMO staff working on phones. The shared backlog defines implementation scope; this document does not claim every screen has been modernized.

## Read this first: scope and authority

This is the design contract for **the Flutter mobile application in `ecopin_app/`**, including all four authenticated roles. “Citizen app” means the citizen experience inside this application, not a separate repository. “Public map” describes the visibility of report data; it does not mean the native map is available without signing in.

This document defines intended UI behavior and role boundaries. It is not evidence that every requirement is implemented, released, or tested on a physical device. The source references below describe the current implementation inspected on 21 October 2026; unfinished work and verification evidence belong in [UI_UPDATE_BACKLOG.md](../UI_UPDATE_BACKLOG.md).

### Resolve a request before choosing a screen

1. Identify **platform**: native Flutter app (`ecopin_app/`) or web (`ecopin-web/`). A browser screenshot or a shared brand does not make their layouts interchangeable.
2. Identify **role**: citizen, officer, field crew, administrator, or signed-out account flow. Role is a workflow/access boundary, not a color theme.
3. Identify **object and task**: public concern, own submission, operational report, cluster, cleanup task, route, account, or queued change.
4. Use the role and map matrices below to find the owning screen. Inspect its callers before changing a shared widget.
5. Read only the relevant contract sections and their source references. Preserve existing authorization, routes, backend values, and privacy boundaries.
6. If the task names a role, keep that scope. If a shared change affects other roles, verify those callers too. If context cannot resolve an ambiguous “map” or “reports” request, clarify that boundary before implementing a different workflow.

### Which source decides what?

| Question | Reference | Rule |
| --- | --- | --- |
| Which native visual/interaction pattern should be used? | This `DESIGN.md` | Apply the design contract; an old screen is not a new visual precedent. |
| What code actually runs and which route is registered? | `lib/routes/app_routes.dart`, router configuration, owning shell/screen | Verify registration and callers; a route constant alone does not prove a usable feature. |
| What colors, type, radii, and component APIs exist? | `lib/core/theme/`, existing shared widgets | Reuse actual tokens/APIs; do not invent an equivalent second system. |
| What permissions, transitions, limits, and data are supported? | Existing providers/services and server contracts | Design copy cannot grant permissions or invent outcomes. |
| What remains unfinished or verified? | Shared UI backlog and relevant tests | Report evidence accurately; a test file's existence is not a passing run. |
| What should the website look like? | `../ecopin-web/DESIGN.md` | Shared civic identity; web-specific layouts do not override native navigation. |

Explicit task instructions may revise this contract. Record accepted revisions here. If code and contract differ, identify the difference and limit the fix to the authorized task; do not silently modernize unrelated screens or claim the difference is already resolved.

### Quick reading index

- **Distinguishing experiences:** role ownership, terminology, map matrix, and source map below.
- **Visual implementation:** Palette and themes; Typography, spacing, and shape; Controls and navigation.
- **Citizen workflows:** Citizen bottom navigation; States, reports, and field work; Public map and place search.
- **Operational work:** role ownership; Crew dashboard and assignment hierarchy; Field-crew preparation and Sync Center.
- **Account/admin workflows:** States, reports, and field work, including administrator, notification, and password rules.
- **Finishing a change:** UI state matrix and acceptance checklist at the end.

## Role ownership and navigation

Runtime scope confirmed 29 October 2026: Officer and Administrator access is web only and Field Crew access is mobile only. `app_router.dart` sends signed-in officer and administrator sessions to `/unauthorized` (see UX-11). Native officer and administrator shells, routes, and the administrator workflow rules later in this document describe retained code, not permission to enable those sign-ins on mobile. Citizen and Field Crew are the only live native workspaces.

All roles share EcoPin identity, light/dark themes, accessibility, and truthful feedback. They do not share every destination, dataset, or action.

| Experience | Primary job | Shell and visible navigation | Scope to preserve |
| --- | --- | --- | --- |
| Citizen | Discover public concerns, submit a concern, follow own reports | `CitizenMainScreen`; **Map · Reports · Report · Alerts · Profile** | Center Report is an action; the other four are destinations. Public discovery and own submissions remain distinct. |
| Officer | Review concerns, organize response work, plan and monitor assignments | `OfficerMainScreen`; **Home · Clusters · Tasks · Reports · More** | More contains Map, Spatial scan, Analytics, Dispatch planning, Crew management, Response logs, and Account. Do not replace this shell with citizen navigation. |
| Field crew | Work assigned cleanup tasks, follow routes, record evidence and sync | `FieldCrewMainScreen`; **Home · Route · Tasks · Reports · Profile** | Task/report detail routes hide this bottom bar. Preserve task context and the local-versus-server distinction. |
| Administrator | Manage supported accounts/settings and inspect audit activity | `AdminMainScreen`; **Home · Users · Settings · Logs · Account** | Own admin routes and authorization. No native admin report-detail route; fleet/algorithm configuration remains outside approved mobile scope. |
| Signed out / pending account action | Sign in, register, verify email, complete required password change | Existing public/account routes | No authenticated workspace shell. A pending password-change token is not an authenticated session. |

Officer and administrator notifications have role-specific route constants even though Alerts is not a bottom-tab destination in those shells. Do not add tabs simply to match citizen navigation.

### Terms that agents must keep separate

| Term | Meaning | Do not substitute |
| --- | --- | --- |
| Public report / concern | Privacy-filtered report visible in public discovery | Full officer/crew operational record or the user's own-report list |
| My reports / citizen Reports | Signed-in citizen's submissions and progress | Every public report in the current viewport |
| Validation | Review/acceptance decision | Response lifecycle or cleanup completion |
| Response status / lifecycle | Current handling stage of a concern | Upload state, priority, or assignment |
| Cluster | Operational grouping of related reports | A numbered visual marker group produced by map clustering |
| Cleanup task | Assigned unit of response work | One public pin or necessarily one report |
| Route | Supplied/planned travel and stop context for crew work | Citizen map camera position or unsupported live ETA |
| Priority / severity | Existing urgency/risk fields | A successful sync or review decision |
| Saved locally / queued | Work held on the device | Server accepted, uploaded evidence, or resolved concern |
| Synced / acknowledged | Actual server outcome for the relevant item | Completion of the cleanup or every item in the queue |
| Empty | Successful request with no matching results | Failed request, missing permission, or unknown queue |

Use the user's language in conversation, but preserve established app labels and backend values. Do not translate the whole application or rename routes as a side effect of a UI fix.

### Map ownership: three different native screens

| Map | Entry / owner | Data and interaction intent | Must not acquire |
| --- | --- | --- | --- |
| Citizen public map | `/maps`; `lib/shared/maps/presentation/screens/maps_screen.dart` (`MapScreen`) | Bounded public reports, marker preview, heatmap, place search, locate, legend/credits | Staff-only evidence, exact-location enrichment, assignment mutations, or crew navigation tools |
| Officer map | `/officer/maps`; `lib/features/officer/presentation/screens/officer_map_screen.dart` (`OfficerMapScreen`) | Existing operational report exploration in the officer workflow | Citizen raised Report action or an assumed public-map fetch policy |
| Crew Route | `/field-crew/map`; `lib/features/field_crew/presentation/screens/field_crew_map_screen.dart` (`FieldCrewMapScreen`) | Assigned task/route context and supported navigation behavior | Public-discovery replacement, fabricated traffic, or unsupported ETA |
| Legacy shared crew preview | `MapScreen(isFieldCrewMode: true)` when used by a caller | Restricted public preview with explanatory guidance | Proof that it is the crew Route screen; empty route-layer flags do not implement routing |

A file under `shared/` is reusable code, not proof that all roles use it. A citizen-map fix must not be copied into the officer or crew maps without checking their own behavior and scope.

## Source map and component ownership

Paths in this section are relative to `ecopin_app/`. These are starting points, not permission to read or change every feature.

| Concern | Existing owner / reference | Reuse rule |
| --- | --- | --- |
| Color, spacing, shape | `lib/core/theme/colors.dart` (`AppColors`) | Use semantic tokens; avoid fresh hex values and parallel constants. |
| Typography | `lib/core/theme/typography.dart` (`AppTypography`) | Outfit and the existing text hierarchy; theme text styles first. |
| Material theme and status extensions | `lib/core/theme/app_theme.dart` (`AppTheme`, `AppStatusColors`) | Keep both themes and native component defaults coherent. |
| Shared action | `lib/shared/widgets/app_button.dart` (`AppButton`) | Primary, secondary, danger, link; retain loading/disabled semantics and growing height. |
| Page-level empty/error state | `lib/shared/widgets/app_state_view.dart` (`AppStateView`) | Named title, explanation, and a working recovery action when available. |
| Staff navigation and avatar | `lib/shared/widgets/app_navigation_bar.dart` | Preserve each shell's destinations; private-media avatar fallback remains supported. |
| Citizen navigation | `lib/features/citizen/presentation/widgets/citizen_navigation_bar.dart` | Raised action and four destination indices are citizen-specific. |
| Citizen role shell | `lib/features/citizen/presentation/screens/citizen_main_screen.dart` | Owns navigation and location-prefill reporting entry. |
| Officer role shell | `lib/features/officer/presentation/screens/officer_main_screen.dart` | Owns primary destinations and the More sheet. |
| Crew role shell | `lib/features/field_crew/presentation/screens/field_crew_main_screen.dart` | Owns Route navigation and detail-route bar visibility. |
| Administrator role shell | `lib/features/admin/presentation/screens/admin_main_screen.dart` | Owns admin destinations, separate from officer work. |
| Public map loading/status | `lib/shared/maps/presentation/widgets/report_map_status.dart` (`ReportMapStatus`) | Persistent area/search/stale feedback; not a temporary floating snackbar. |
| Public pin and preview | `lib/shared/maps/presentation/widgets/report_marker.dart`, `report_map_preview.dart` | Preserve selected state, accessible activation, and public precision. |
| Report response presentation | `lib/shared/reports/presentation/widgets/report_status_presentation.dart` | Normalize display labels only; use existing theme-aware status mapping. |
| Private photo delivery | `lib/shared/widgets/private_media_image.dart` | Retain authenticated delivery and truthful unavailable fallback. |
| Citizen map request bounds | `lib/shared/reports/providers/public_report_map_provider.dart`, `lib/shared/reports/data/datasources/public_report_map_datasource.dart` | Keep bounded public queries and truncation feedback; do not switch to an unbounded report download. |
| Route names | `lib/routes/app_routes.dart` | Use existing role constants and encoded IDs; inspect router registration before changing navigation. |

Shared-widget edits require checking every affected role/caller. Feature-specific layouts and workflows stay with their feature; sharing tokens does not require a universal configurable screen.

## App purpose and information architecture

### PDT-01: citizen priority selection (28 October 2026)

Citizen Create Report uses Non-urgent (default) and Urgent tap choices in Details. Urgent requires one preset reason: Community Event/Liga, School/Hospital Zone, Severe Obstruction, or Public Health Hazard. A separate explanation is optional (1000 characters). Review shows the selected priority and urgency details; switching back to Non-urgent clears them. Priority and reasons survive offline saving and sync. Citizen urgency requests require officer verification and do not approve dispatch or promise response timing. Keep this separate from calculated incident severity. Web citizen submission is deferred; the shared API accepts the same contract.

### PDT-02: citizen trust gate (28 October 2026)

Gemini review follow-up: successful eligibility remains cached between screens for offline drafts, with account-change/rejection invalidation. Profile lists the signed-in citizen's blocked Urgent drafts and offers explicit confirmed Non-urgent conversion or eligible Urgent retry. Preserve evidence and request identity. Scope report/media queues to their recorded owner and recheck the account before sending. Quarantine unowned legacy records rather than exposing/submitting them as the next signed-in user. Lock copy lists only unmet requirements; completed crew tasks remain SWMO review territory. Reused staff panels clear the prior report's draft.

Citizen Profile shows server-reported trust and a refresh action. Start at 50/100; Urgent requires 70. Human-verified valid reports earn 10; proven false urgency removes 30 and requires both seven days and three consecutive valid reviews for recovery. Ordinary rejection, low severity and declined urgency do not mean dishonesty. Disable Urgent while locked or when eligibility is unknown, with explanatory text; keep Non-urgent reporting available. Server eligibility is authoritative, including offline sync. Keep rejected urgent drafts and their reason; do not silently downgrade them. Trust caches clear on account changes. Officer report details expose an explicit online trust review, mandatory reason and a confirmation for proven false urgency. Under PDT-04, crew report details expose non-scoring offline observations instead; direct trust decisions require officer/admin review. Failure retains the reason and retry identity. Administrative corrections remain an auditable API operation. This does not alter incident severity, dispatch approval, or account suspension.

Design for a phone held in one hand: find a concern, report it with location and evidence, then follow its progress. Use native Flutter controls and device safe areas rather than reproducing the web header, hero, hover interactions, or desktop sidebar. Keep the current role routes and platform back behavior.

| Citizen control | Job | Existing destination |
| --- | --- | --- |
| Map | Explore public concerns | `ProtectedAppRoutes.maps` |
| Reports | Follow the citizen's own submissions | `ProtectedAppRoutes.reports` |
| Report | Start a new concern; an action rather than a selected tab | Existing location-prefill flow → `ProtectedAppRoutes.createReport` |
| Alerts | Read notifications and their unread count | `ProtectedAppRoutes.notifications` |
| Profile | Manage the signed-in account | `ProtectedAppRoutes.profile` |

Citizen navigation is the first rollout of the raised-action treatment. Officer and administrator shells retain their existing shared navigation. Crew uses the compact citizen-family treatment without a raised action. Do not imply that their destinations, permissions, or workflows changed.

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

The values above are the same as the web landing and staff-shell tokens (`--landing-*`, `DashboardShell.module.css`). Quiet surface dark `#242424` corresponds to the web `--surface-elevated`; there is no separate native value.

Semantic status colors come from `AppStatusColors` (in `app_theme.dart`) and match the web staff shell exactly:

| Status role | Light | Dark | Web token |
| --- | --- | --- | --- |
| Success | #2E7D32 | #83CBA0 | `--success` |
| Warning | #B45309 | #FCD34D | `--warning` |
| Error | #D32F2F | #FCA5A5 | `--error` |
| Information | #0369A1 | #82B6FF | `--info` |
| Feedback (purple) | #6D28D9 | #C4B5FD | `--purple` |

The raw `AppColors.warning` (#F9A825) and `AppColors.info` (#0288D1) constants are legacy brights that fail text contrast on white. Do not use them for text, icons, or badges; read `AppStatusColors` from the theme instead. Dark text goes on amber fills.

Success, warning, error, and information keep their semantic meaning. Always accompany colors with written states. Verify contrast after overlays/opacity; target 4.5:1 for ordinary text and 3:1 for large text and essential control boundaries. Do not introduce lime accents or permanently dark screens. Use existing map providers and attribution; this redesign requires no API keys or environment changes.

## Typography, spacing, and shape

Use bundled Outfit. Body 16, secondary body 14, labels 14, captions at least 12 logical pixels. Headings 20–32 for working screens; large promotional typography belongs only on the introduction. Technical payloads may use monospace; navigation and operational labels may not. Long names, addresses, badges, and actions wrap. Support system text scaling without shrinking text to fit.

Every shared typography definition explicitly carries the Outfit family. Setting only `ThemeData.fontFamily` does not cover styles supplied directly to native chips, buttons, and dialogs. Selected choice-chip labels use the foreground associated with their selected container; normal and selected labels must both remain readable in either theme.

Spacing uses the shared 4-point rhythm. The `AppColors` tokens are 4/8/16/24/32/48/64 (`spaceXS`–`spaceXXXL`). 12 and 20 are allowed inside compact related groups. This is the same rhythm the web uses; the web also allows 40/56/80/96 for its landing sections, and those values have no native equivalent.

Shape tokens (UX-02, the same as web): pill buttons/chips (`radiusButton`, `radiusChip`), 12 inputs and menus (`radiusInput`), 16 cards and panels (`radiusCard`), 24 dialogs and bottom sheets (`radiusDialog`, top corners only on sheets). **Every content card uses 16**, including citizen My Reports, public List, Alerts, and crew Sync Center/Preparation cards. Some older text said 24dp cards, and `reports_screen.dart` still hard-codes 24; that is drift to correct, not a precedent. The only exceptions with their own radii are the navigation bars (12dp top corners) and the floating citizen map toolbar (24dp, which matches the dialog/sheet tier).

Type weights: display/h1 700, h2/h3 600, h4–h6 500, body large/body/caption 400, label 500, button 600. One deliberate exception: dialog titles use `AppTypography.h5` raised to w700 (20dp), never h3. On the web, landing headings and the staff page title use 500, because their larger sizes carry the hierarchy. Native working screens are smaller, so they use the heavier weights above. Do not copy web weights onto native styles, or native weights onto the web.

Pushed screens use the plain theme canvas (`#FFFFFF` / `#121212`). In light mode, the citizen and field-crew tab shells use `AppColors.tabCanvasLight` (`#F2F4F7`, equal to the divider color at 50% over white) so the white navigation bar's 12dp corners stay visible. The crew shell currently computes this value inline; it should read the token. These two shells are the only tinted canvases (guarded by `citizen_navigation_test.dart`). Dark mode uses the ordinary background/surface distinction. Do not add other ad-hoc canvases. Do not create empty placeholder files; the unused `loading_indicator.dart` and orphan `report_details_widgets/status_badge.dart` were deleted. Use thin dividers and quiet elevation only for floating elements. Do not place every data point in an equally prominent card.

## Controls and navigation

### Welcome screen

The signed-out introduction leads with **A cleaner Pasig starts with us.** Use a civic-blue field in both themes, a white wordmark, and a single soft-green (`environmentalDark`, #83CBA0) emphasis on “us.” The web hero puts “us.” in blue because its page is white. Both platforms follow the same rule: “us.” takes the one brand accent that contrasts with its background, and nothing else in the headline is colored. Set the headline in medium Outfit, with ordinary readable body text and a compact three-step sequence: Snap & pin, Describe, Follow up. Avoid script lettering, gradients, decorative badges, and repeated cards.

The bundled `assets/illustrations/welcome_neighborhood.svg` is an original folded-neighborhood drawing: a river, a footbridge, garden plots, and one leaf pin. It is decorative, excluded from screen-reader output, and does not represent live reports or geographic data. Keep all meaningful copy as native text.

Place **Sign in** and **Create an account** in a quiet, theme-aware bottom section using the shared buttons and existing routes. The map currently requires authentication, so the introduction must not offer an anonymous-map action. Constrain the reading width on tablets; let the whole screen scroll on short displays and with enlarged text. Preserve device safe areas, full text scaling, a semantic heading, and keyboard activation.

Verification: account layout tests cover small phones with 2× text, landscape, tablet, both themes, and the two account destinations. Foundation preview tests render the native welcome screen in both themes. Physical-device safe areas and TalkBack remain device acceptance.

### Shared controls

- Target at least 48dp interactive areas. A button's configured height is its minimum; it grows for multiline/scaled labels. Named loading states disable duplicate actions.
- Inputs have labels, helper/error text, keyboard/autofill appropriate to their value, visible focus, and named show/hide-password actions. Preserve controllers, validation, submissions, and values after failures.
- Shells keep role destinations, safe areas, readable selected labels, accessible notification counts, and predictable back behavior. Public reporting, My reports, crew objectives, and officer review remain distinct tasks.
- Officer and administrator shells use the shared native navigation bar. Crew opts into its compact variant: five equal destinations, 12dp top corners, a fine 16×2dp selection line, Outfit 12 regular labels, 48dp minimum targets, a local 1.3 navigation text-scale cap, and the device bottom inset. No raised center action or empty action slot. Like the citizen shell, it uses the `tabCanvasLight` page canvas in light mode to reveal the white bar corners; dark mode uses the existing background/surface distinction. Five-tab shells use Home rather than a long Overview label. Officer secondary destinations belong in the scrollable More sheet. Keep crew detail-route navigation behavior intact. Navigation labels and supplementary badges follow platform text-scale limits; speak the full unread count. Main content and actions continue to grow with system text size.
- Citizen navigation uses the raised circular Report action described below. Citizen-map status belongs in the top toolbar beside Map/List, stacking below those controls at narrow widths or enlarged text. Keep map pixels visible behind the shell navigation. Account avatars elsewhere use private-media delivery, including fallbacks.
- Forms use logical sections with inline errors and an explicit final review where supported. Keep map attribution and action buttons clear of keyboard and device insets.
- Dialogs/sheets have a clear title, dismiss/back behavior, scrollable content, and usable actions at large text sizes. Continuous motion has pause controls. Respect reduced motion outside the approved web landing behavior.

### Citizen bottom navigation

Use `CitizenNavigationBar` in the citizen shell. The supplied navigation reference informs the compact five-position layout, raised center action, fine selection marker, and lighter labels. Use EcoPin's palette and destinations.

- Order: **Map · Reports · Report · Alerts · Profile**. Four destination indices remain unchanged; reporting never becomes a fifth page or a selected tab.
- Attach the surface to the bottom and both screen edges, with only 12dp top-left and top-right corners. No outer margin, floating pill, bottom corner rounding, or gap below the bar. Paint the surface through the bottom device inset and keep every control above it. The citizen shell extends its body behind the bar so the transparent space beside the raised action reveals the screen rather than a rectangular scaffold background.
- The surface is white in light mode and neutral charcoal in dark mode. Keep the rectangular base shadow-free so it cannot create a gray strip beside the raised action on Reports or Alerts. The center has a 72dp surface-colored circular shoulder around a 56dp circular action, which retains its own quiet elevation. The visible bar is 80dp high. Reserve 104dp plus the device's bottom inset for the whole component (80dp bar plus the 24dp raised shoulder), so the raised area remains inside the shell's layout and hit-test bounds.
- The report action uses civic blue `#0052CC` and a white camera icon in both themes. Keep its visible **Report** caption and full accessible name, **Report an environmental concern**. During location lookup, disable repeat activation and announce **Finding location**. Preserve current location failures and manual map-selection recovery.
- Use the Bootstrap font bundled with `icons_plus` for map, document, camera, notification, and person icons. Icons are generally 24dp; the central camera is 26dp. Selection adds a short 16 × 2dp marker above the icon and changes icon/label color. It must also expose the native selected state.
- Labels use bundled Outfit, 12dp, regular (400), with ordinary letter spacing. Use the readable blue token for selected labels, secondary text for inactive labels, and a maximum navigation text scale of 1.3. Main content keeps the system's full scale. Keep at least 48dp tap targets and native keyboard focus/activation.
- Alerts retain the visible capped `99+` badge and full unread count for assistive technology. Loading or failed counts remain identifiable. Profile uses the live circular profile photo or initials described below.

`icons_plus` 5.0.0 subclasses `IconData`, which is final in the app's installed Flutter SDK. Until the upstream package supports that SDK, the citizen widget declares four constant native `IconData` values using the package's Bootstrap font and matching codepoints. Do not import the incompatible Dart barrel or patch the SDK/package cache. Recheck these bindings when upgrading the icon package.

Verification: `test/ui/role_navigation_test.dart` exercises all role routes, both themes, 320dp width, 2× system text, and a 32dp bottom inset. `test/ui/citizen_navigation_test.dart` covers responsive widths, report activation/loading, keyboard activation, and renders the actual Flutter navigation states for visual review. Real Android GPS, TalkBack, and gesture-navigation acceptance remain device checks.

## States, reports, and field work

Loading, refreshing, empty, failure, unavailable, permission denied, and stale data are different states. Keep existing data visible on refresh. Offer only working recovery actions. Do not present failed loading as an empty list.

Separate validation (review decision) from response lifecycle, priority, assignment, and synchronization. Human-readable display labels may normalize underscores and case; never alter values sent to the backend. Reported, queued locally, uploading, synced, and completed on the server are different outcomes.

Explain actual network policy and pending work. Offline copy must not promise every change is saved or automatically synced. Keep recoverable drafts, queues, authorized lifecycle actions, and the informational conflict model intact. Hide or honestly disable unfinished actions.

Present report location, description, evidence, review state, response progress, consent/agency instructions, and permitted next action in a clear hierarchy. Before/after evidence identifies its provenance. Secure media still uses authenticated delivery; unavailable photos show a truthful fallback. Fullscreen inspection uses contain-fit imagery, labeled navigation, zoom where supported, and captions. Editorial photos and category illustrations are never evidence for an incident.

The reporting form keeps a named location → details → media → review progression. Without a detected location, require explicit map selection before continuing; a default Pasig view is not a detected location. Show an address with coordinates when available and a working address retry when unavailable. Details includes an optional Nearby landmark textbox (300 characters) as citizen-provided extra directions. Preserve it in review, offline drafts/retries, rejected-report prefill and authorized report details. It never replaces the map pin, GPS coordinates, geocoding or polygon-derived barangay. Keep entered values after rejection and distinguish a report saved on this device from a server acknowledgement.

Rejected and uncertain photos use the same English “Unable to verify this photo” explanation and do not attach automatically. Show a photo preview, Retake photo, Choose another photo, and Request manual review; require a nonblank explanation describing the concern and where it appears before enabling the review action. Explain that AI can miss relevant details without claiming there is no concern or promising acceptance on retry. Label confirmed review attachments “For manual review — not yet verified” and repeat their explanations before submission; removing a photo removes its review request. Failed or unrecognized checks show “Photo check unavailable,” distinguish failure from rejection, and offer retry or an explicit review request. Review submissions require a connection and retain the form and existing attachments if offline. An appeal routes the report to an officer and never grants automatic approval. Keep file limits, location verification, submission quotas, and staff authorization intact.

Media selection has a visible checking state, repeat-action lock, persistent recoverable errors, and a device-settings action for denied access. Report videos use camera recording only; do not reintroduce a gallery-video option without an explicitly supported provenance/priority policy. Every clip is at least 5 seconds; the administrator chooses the maximum from 5–10 seconds, persisted in `system_settings.report_video_max_seconds`. Load only the dedicated authenticated media-policy projection, display the saved range, refresh before recording/submission, and validate exact metadata. Keep the camera configured to the saved nominal maximum, but allow at most 100ms above it in both app/server validation for recorder/container stop timing. Keep the minimum strict and do not truncate metadata to whole seconds. A policy-load failure offers retry/photos and must not silently accept video against a hard-coded fallback. Server enforcement probes uploaded bytes independently. Native System settings and web administrator settings edit the same value. See [report video policy](../ecopin_backend_node/docs/report-video-policy.md) for migration, enforcement, AI fixes, and verification limits. Keep photo count/combined-size and video format/duration limits visible. Read actual video duration through the existing player's initialized metadata; never infer duration from file size or truncate it before validation. Selected local photos support uncropped zoom and previous/next navigation; video inspection has explicit play/pause, position, and retry. Identify both as unsent media. Do not autoplay. Controllers are released after inspection/metadata reads. See [Flutter's video-player lifecycle guidance](https://docs.flutter.dev/cookbook/plugins/play-video).

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

### Citizen viewport loading and attached status bar

This policy applies to the citizen `MapScreen` and its existing shared-preview callers, not automatically to `OfficerMapScreen` or `FieldCrewMapScreen`.

- Load the initial visible area immediately after the map is ready. Automatically select the latest bounds after 150ms without camera movement; there is no manual Search this area action. Coalesce rapid moves into one request.
- Reuse up to six recently loaded public areas for 60 seconds. Complete cached areas can serve contained viewports with their reports filtered to the new bounds; truncated pages can only serve their exact bounds. Cache lookups do not extend freshness. Respect wrapped longitudes/date-line queries.
- Keep loaded pins while another area request or refresh is pending. A late response for an older area must not replace the selected area's results. Keep the map controller/camera mounted through loading, retry, theme and Map/List changes.
- Report count and loading/error/stale feedback belong in the top Map/List toolbar. Place them beside the view controls at ordinary phone widths; stack them beneath the controls at narrow widths or enlarged text. There is no status footer above the citizen navbar. Never claim that old retained pins/count fully describe a new viewport while its request is pending.
- Preserve a 60-second refresh while the map is active and the app is resumed. Refresh/retry bypasses the area cache. Pause camera-triggered loading and periodic refresh while List is visible; restore the map's laid-out bounds after returning.
- Keep the existing bounded page: up to 200 public reports, with the newest-200 disclosure and zoom-in instruction when truncated. Do not load the entire dataset or label truncated results as all reports.
- On request failure, retain useful loaded pins and expose retry. Distinguish valid zero reports from failure. Do not weaken public filtering or geolocation precision. These are request scheduling/cache guarantees; real-device network and rendering latency require separate measurement.

### Pins, previews, and tools

#### Native pin and visual-cluster adaptation (21 October 2026)

The shared native `ReportMarker` and `ReportClusterBadge` adopt web contract section 9's pointed silhouette, white separation outline, restrained shadow, status badge, and blue selection treatment. The native interactive footprint is **56 x 64dp**, with a **50dp** circular face, **12 x 10dp** downward tip, and **24dp** status/layers badge. Map markers and visual clusters use `Alignment.topCenter`: in the installed Flutter map API this puts the widget above the coordinate, with the bottom tip at that coordinate. Update every caller's dimensions when changing this frame, including officer task selection and the legend.

Public map results currently contain no evidence thumbnails. Show a concern icon inside the frame, with a location-icon fallback for unknown categories. This is a deliberate native fallback, not a photograph or proof of evidence. Do not add per-pin evidence requests, expose private photos, or imply full web photo-pin parity. Photos require a supported privacy-safe data path.

Map status treatment follows the canonical matrix (UX-03, below) with the web pin icons: unresolved/submitted/pending/rejected use error + alert; in-progress/acknowledged use information + clock; pending owner consent uses information + lock; waiting for feedback uses feedback purple + message; resolved uses success + check; closed and unknown use muted + double check / help. Amber is never a pin status. Use theme-aware semantic display colors and readable badge foreground. This changes map presentation only, not lifecycle values or unrelated list badges.

Native visual clusters retain the count (visually capped at `999+`, full count spoken), civic-blue border, offset backing circle, and Layers badge. The map legend must show this actual shared cluster pin as a noninteractive example, explain its count, and describe zoom/circular expansion; prose alone is insufficient. This uses the web operational cluster family. Do not import the public web preview's representative-photo-only clusters or geographic grouping algorithm. Keep the installed native package's zoom and circular **spiderfy** behavior: opening coincident reports still arranges them around the cluster. Preserve original coordinates, keyboard/semantic activation, and reduced-motion settings. The blue ring identifies selected report pins or focused cluster controls; do not invent group-selection or overdue state unavailable to these visual groups.

Shared callers include citizen/public preview, officer map, officer custom-task selection, and the legend. Crew Route remains a separate screen. `test/ui/map_pin_preview_test.dart` exercises both themes at large text; `test/ui/public_map_ui_test.dart` checks native activation and retained cluster expansion.

Public map pins use written response states and recognizable status icons, with a selected ring and named native 48dp actions. Cluster counts expose the full count to assistive technology; the compact visual count may cap at 999+. Keyboard and semantic activation use the existing clustering package's zoom/spiderfy action. Reduced motion disables that package's transition durations. Keep its algorithm and public viewport limits intact.

The selected report is a stable snapshot while the map refreshes. Its scrollable bottom sheet shows the full title, concern, response status, description, and any approximate-location disclosure. Closing the sheet precedes navigation to the existing report route. Do not fetch a more precise location to enrich a public preview. Map refresh failures retain loaded pins with a stale-data notice and retry. Theme changes update the actual tile layer without resetting the map. The current native credits are linked from the named Map legend and credits dialog (`ReportMapInfo`). Keep both OpenStreetMap and CARTO links reachable and readable. This describes the current UI location, not a determination of provider attribution compliance; any attribution-placement change must check the applicable provider requirements.

Map tools have named search, heatmap, location, and legend actions. Location and privacy actions lock repeat requests and provide persistent recovery after denied access or failed saves. A failed privacy read is not consent. The legacy shared crew preview must not invent routes, travel times, traffic, weather, or crew counts; direct crews to their assigned task for supported work.

Place search keeps one 300ms debounce. Explicit submission/retry flushes that timer, and late responses cannot overwrite a newer query or cleared search. Distinguish service failure from a valid empty result. Keep history after removal/storage failures and expose recovery. Opening a place remains possible if saving its recent-search entry fails; explain that failure after returning to the map. Preserve the existing history key, format, deduplication, and ten-item limit.

Microphone initialization is an explicit opt-in through Use voice search. Opening search does not request speech access. Show listening, denied, unavailable, and stop failures honestly, with a typed-search fallback and device-settings recovery. Rebind and release the speech SDK listeners across openings; manual typing invalidates late voice results. The whole search surface scrolls above the keyboard, with labeled input, clear/back controls, wrapping place names, and named history actions. Synthetic preview tests complement separate Android microphone, GPS, settings, keyboard, and TalkBack acceptance.

## Crew dashboard and assignment hierarchy

The dashboard starts with a short greeting. The upper-right corner holds the notifications bell and a compact Sync Center icon, each with a 48dp target. Next come the current task and its primary Open current task button. Then, in this order: the two summary metrics (Personal Done, CSAT; see UX-21), a single tappable route row, compact loaded-assignment progress, up to two queued tasks, collapsed device records, and preparation. Keep the greeting short and omit introductory/helper paragraphs that repeat the action labels. Use a titleLarge current task title, with full wrapping rather than truncation. Queue cards retain title, location, written status and priority without a repeated Open task details footer. Device records summarizes local completion/held counts and expands to their records and the local-versus-server explanation. Preparation remains a quiet text action with a 48dp target. Keep the task title and supplied address readable in full. Use written priority and response state; do not rely on a colored dot. Opening details is not starting a task, so the button must describe navigation accurately.

Retain the established in-progress → route order → high/urgent priority → creation-time ordering. Completed/cancelled records and locally held or recorded-complete tasks are not proposed as the next task; their records remain accessible through their sections and the full assignment list. Local receipts describe this device/session and do not prove a server acknowledgement. Do not mutate loaded models while arranging the dashboard. Detail links keep existing routes and encoded IDs. Returning from details refreshes local queue counts without silently refetching and replacing task records.

Progress describes loaded assignments, including any cancelled records in its denominator. It is not a shift or today's performance without a supporting filter. Show the count in written text and the progress indicator's label, leaving its numeric accessibility value to Flutter. Route context shows the supplied stop count and the current task's next recorded sequence when available. Omit dispatch distance/time estimates and their explanatory paragraph from the compact dashboard; route planning remains in Route. Never invent live ETA or remaining-work claims. Missing route data is unavailable rather than a completed route. Explicit route refresh reloads the existing route provider; routes, authorization, and routing calculations remain unchanged.

Keep useful assignments and route context during refresh failures, with distinct loading, empty, unavailable, stale, and retry states. An empty assignment list does not prove the crew finished its shift. Cached records remain identified as possible cached data. The crew sync control uses actual queued changes, photos, and removals, plus the current mode and detected network. Include photo-only failures and unknown/stale queue feedback. Never label an unknown queue as synced, or hide a failure after an arbitrary short timer. It remains a named, keyboard-accessible destination to Sync Center with a 48dp target. Pulse the icon when work is queued or syncing; respect reduced-motion settings. Persistent error/unknown states use distinct icons and an accessible name/long-press tooltip with actual queue, connection, and policy details. Full counts and recovery remain in Sync Center.

The global citizen/officer/admin offline banner and legacy queue indicator have separate acceptance under A09. Improving the crew control does not claim that those other surfaces expose complete sync state.

## Field-crew preparation and Sync Center

Both screens use the shared theme, 16dp (`radiusCard`) cards with quiet borders, readable Outfit labels, 48dp actions, safe areas, and one scrollable content surface. Group related facts within cards. Short facts may share a row at ordinary text sizes; enlarged text and long values stack and wrap. Dates include the year and local time. Connection labels identify the network type without implying that the server is reachable.

Preparation describes assigned record information, evidence metadata, notes, and available route records. Full-size photos, reference lists, and map tiles may still need a connection. A reference-service check is not an offline catalogue download. Show each step's written state, actual cached counts, approximate record-storage estimate, and preparation time. Preserve failed section messages through the final result, including unavailable assigned report groups and linked records not returned by the service. Useful records can remain cached while the package has gaps. An earlier restored receipt does not verify every section or current assignment; identify it and offer an update. Retry must recover from estimation as well as download failure without clearing usable cached work.

Offline preparation is an explicit download separate from queued sync policy. Do not promise that Offline Only disables all device network requests. Enabling it is optional and explicit, and it pauses queued syncing until mode changes. Preserve the existing preference keys, enum values, gate rules, and download endpoints. Confirm preference storage before updating the displayed value; retain the previous setting and expose a recoverable error if saving fails.

Sync Center separates queued changes, photo uploads, and photo removals. Repeatedly failed photos are a subset of queued uploads, not another total. Failed queue reads remain unavailable or explicitly stale rather than showing nothing pending. Explain the selected mode and allowed network, with connection refresh and settings recovery. The existing gate remains authoritative for a commit, including its mobile-data confirmation. Guard repeat requests while checking, confirming, syncing, or resetting retries. Resetting a photo's retry allowance does not mean it uploaded; keep that distinction in feedback.

Last-run information includes changes acknowledged, merged, awaiting retry, and not applied, plus attempted/succeeded/failed photo uploads and removals. Review/conflict flags can overlap those totals; a server acknowledgement does not necessarily close a report. Show actual server outcome messages for merged, contested, and verification-required updates. Keep this summary informational with expandable details and a named 48dp dismiss button. It remains until dismissed, resets for a new completed run, and provides no invented manual conflict-resolution controls. Error and partial-failure feedback persists while the relevant state remains.

UI verification uses simulated services and real provider/widget interactions alongside the existing sync and offline regression suites. Android network changes, storage failures, background uploads, real queued evidence, restart recovery, safe areas, and TalkBack still need separate device acceptance. The UI changes do not alter mutation ordering, conflict decisions, photo-sync algorithms, authorization, or database structure.

## Boundaries and verification

Preserve authentication, role access, API contracts, Supabase behavior, backend lifecycle, geolocation precision, private media, consent, and sync. Do not add unsupported exports, saved reports, admin capabilities, or field-crew web access. Dependencies remain visible in [UI_UPDATE_BACKLOG.md](../UI_UPDATE_BACKLOG.md).

Validate narrow/ordinary phones, landscape/tablet where supported, keyboard, safe areas, large text, both themes, long content, no photos, empty/error/refresh, and denied permissions. Crew checks include offline/queued/partial failure/server acknowledgement. Run targeted widget tests and analysis during batches; run broader tests and representative device previews before completion. Record what was actually verified in the backlog.


## Layout recipes and visual hierarchy

These are implementation rules for new or modified screens; they do not certify every legacy screen already conforms.

| Screen type | Recommended hierarchy | Avoid |
| --- | --- | --- |
| Working list | Native title/context → search/filter controls → count/scope → records → pagination/recovery | A promotional hero, invented summary metrics, or a separate prominent card for each field |
| Report/task detail | Identity and written state → permitted next action → location/context → evidence → history/supporting facts | Mixing validation, priority, lifecycle, and sync into one badge; unsupported action buttons |
| Form | Title and step/context → labeled fields → inline validation → review where supported → submit/result | Losing entered values on failure, keyboard-covered actions, or success before acknowledgement |
| Map | Compact view/status toolbar → map as primary work surface → named tools → selected report sheet | Status text drifting over pins, resetting camera on fetch, or public/staff data mixing |
| Operational dashboard | Current actionable work → supported progress/context → secondary work → recovery/sync | Decorative KPI grids, fake real-time claims, or treating an empty list as shift completion |
| Settings/account | Related labeled groups → current saved value → explicit changes and recovery | Displaying an unsaved preference as persisted, or requiring undocumented gestures |

Use existing native app bars: theme-aware background/foreground, centered title, and quiet elevation. Standard content uses 16dp side padding, 8–12dp within compact related groups, and 24dp between major sections unless an existing component already owns that space. Do not add duplicate padding around shared components. Use the existing spacing tokens rather than mechanically making every gap identical.

On phones, favor one readable column. On wide/landscape screens, constrain reading width and adapt groups only when the workflow benefits; do not stretch account forms edge to edge or import a desktop sidebar. Cards use the 16dp `radiusCard`. Bars have their own radii: navigation bars have explicit 12dp top corners, and the citizen map toolbar floats within 16dp side margins with a 24dp radius.

Allow long titles, addresses, IDs, status labels, and translated/scaled strings to wrap or remain inspectable. Truncation is acceptable only when the full value has an obvious accessible way to be read. Use selectable/copyable technical identifiers where the workflow requires them. Fixed-height decorative arrangements must not clip meaningful content.

### Color and type decisions agents commonly confuse

- Civic blue is the primary action/selection identity in both themes. Dark-mode readable links use `AppColors.linkDark`; do not use the filled-button blue indiscriminately for small text on charcoal.
- Environmental green is a restrained brand accent. It is not a universal color for all statuses or all crew screens.
- Use `AppStatusColors` and existing status presentation for response states. A lifecycle badge must include a label; color/icon alone is insufficient.
- The palette table's “Role” means a **semantic color role**, not a user role. Citizen/officer/crew/admin do not each get a different brand palette.
- `AppTypography` contains larger display styles for approved contexts. Their existence does not require 40dp headings on routine working pages. Typical working titles remain 20–32dp; welcome copy follows its own contract.
- Prefer `Theme.of(context).textTheme` and component themes. When constructing a direct style, retain Outfit explicitly, suitable weight, contrast, and system scaling.
- Body text uses full system scaling. The citizen and crew navigation's 1.3 scale cap is a local navigation exception, not a global app cap.
- Interactive targets are 48dp on native (Material guidance). The web uses 44px for most controls and 48px for primary actions. This is a deliberate platform difference. Do not lower native targets to 44 to match the web.

### Canonical report status colors (UX-03)

One matrix across web and app: `unresolved` (also submitted, pending, rejected) red (`AppStatusColors.error`), `in_progress`/`acknowledged`/`pending_owner_consent` blue (`info`), `waiting_for_feedback`/`responded` purple (`AppStatusColors.feedback`), `resolved` green (`success`), `closed` and unknown grey (`onSurfaceVariant`). The hex values are in the status table under Palette and themes. `reportStatusColor` in `report_status_presentation.dart` is the single source for `StatusBadge`; `ReportMarkerStyle.forStatus` in `report_marker.dart` must use the same mapping so a tapped pin and its badge never disagree. Amber (`warning`) is not a lifecycle status color. Web counterpart: `REPORT_STATUS_COLORS` in `ecopin-web/lib/helpers/statusHelpers.js` (documented in `ecopin-web/DESIGN.md`). Only one `StatusBadge` exists (`reports_screen_widgets/status_badge.dart`, re-exported from `shared/maps`).

### Map constants, bounds and attribution (UX-04)

Pasig defaults live in `lib/core/constants/app_constants.dart`: `pasigInitialCenter` (14.575, 121.08), `pasigSwmoDepot` (14.561433, 121.075636; fallback for crew route maps), `pasigBounds`, `pasigMinZoom` and `pasigCameraConstraint`. Every Pasig-wide `FlutterMap` (public `MapScreen`, officer map, spatial scan, crew map) sets `minZoom: pasigMinZoom` and `cameraConstraint: pasigCameraConstraint`; location pickers and single-report detail maps are intentionally unconstrained. `MapScreen` mounts `ReportMapCredits` (OpenStreetMap + CARTO links) bottom-left on the map itself, in addition to the legend dialog; never remove it. Web mirror: `ecopin-web/lib/map/pasigMapConstants.js`.

### Issue categories and CSAT scale (UX-05)

Six categories, keys matching the backend `report_issue_type`: `waste`, `flooding`, `pollution`, `infrastructure`, `illegal_logging`, `others` (`issueTypeLabels`). Create Report step 2 has an optional category chip picker; the key is sent as `issue_type` (also queued offline in `offline_reports.issue_type`, schema v11) and the backend uses it as the initial type before AI classification, which may still refine it. CSAT is 1 Very Dissatisfied, 2 Dissatisfied, 3 Neutral, 4 Satisfied, 5 Very Satisfied via `CsatRatingScale`; do not hand-write emoji or labels. Web mirror: `ecopin-web/lib/helpers/csatScale.js`.

### Router dead ends, 404 and contrast rules (UX-11, UX-12)

- Officer and admin sessions have no mobile workspace. A signed-in officer is always routed to `/unauthorized`, which shows a sign-out action (it signs out, then goes to `/landing`) so the router and the auth listener cannot bounce. The Admin overview's report card opens the web dashboard (`WEB_BASE_URL` + `/dashboard`) externally; never `push` an `/officer/*` route from an admin screen. The router's 404 uses `AppStateView` and theme colors only (no `redAccent`/`Colors.grey`).
- Never hardcode `AppColors.textPrimaryDark`, `Colors.grey.shadeNNN` or `Colors.black87` for text that can appear in both themes; use `colorScheme.onSurface` / `onSurfaceVariant`. Surface boxes that sit on the same-colored canvas (`colorScheme.surface` on `#FFFFFF`) carry a 1dp `colorScheme.outlineVariant` border. Text on brand blue `#0052CC` is white; text on amber is dark.

### Auth suite, profile and report creation rules (UX-17, UX-18, UX-19)

- **Recovery:** `Login` links to `ForgotPasswordScreen` (`/forgot-password`, public). It calls `POST /api/auth/forgot-password`, shows the same neutral "if an account exists" message either way, and the emailed link opens the web page `/reset-password` (token in the URL fragment) where the new password is set. Web `/auth` has the same "Forgot your password?" link. The Supabase Auth redirect allow-list must include `<FRONTEND_URL>/reset-password`. Password minimum is 8 everywhere (register fallback, meter, server policy).
- **Auth screens:** field errors appear inline once (no repeated banner for empty fields). `EmailVerification` and `RequiredPasswordChange` use only the AppBar back arrow (no bottom "Back to sign in"). The password-rules reload button has 16dp above it. `LandingScreen` shows the dark logo asset unfiltered and its sheet radius is 24dp.
- **Profile:** `ProfileScreen` has no role-gated officer controls. "Remove photo" is available to every role that has an avatar. Buttons are `AppButton` (Log Out and secondary actions `secondary`, Delete Account `danger`); name and email use `AppTextField` (email is read-only via `isLoading`). The citizen tab bodies get their bottom clearance from `Scaffold.extendBody` (`MediaQuery.padding.bottom` already includes the navbar's reserved height), so scroll views must add `MediaQuery.paddingOf(context).bottom` as `ReportsScreen` and `NotificationsScreen` do.
- **MapScreen** is citizen-only: no field-crew flags, route/crew layer stubs. Crew maps live in `FieldCrewMapScreen`.
- **CreateReportScreen:** progress is shown once, by the interactive step bar (`_buildStepNavHeader`); there is no linear bar, "Step X of 4" label, or large "Step X:" heading. Going back is the AppBar arrow (Previous step) or the step chips; steps have a single primary bottom button. Review "Edit" buttons are 48dp. Leaving step 1 with any entered data (title, description, landmark, category, media) asks "Discard this report?" before popping.

### Citizen details and field-crew rules (UX-20 to UX-26)

- **Report details:** the only Withdraw control is the card at the bottom of `ReportDetailsBody` (there is no AppBar delete icon). The shared details screen is citizen-only: no `isOfficerUser` branches or officer-route links. `SatisfactionRatingScreen` shows only the rating, optional feedback and the reinspection flag; photos and crew notes live in the details body. CSAT labels/emojis come from `CsatRatingScale` only.
- **Crew dashboard:** the header carries the notifications bell (`NotificationBadgeAction(role: fieldCrew)`) beside the sync indicator. The dashboard shows two summary metrics (Personal Done, CSAT) that link to the Performance screen, which owns the full breakdown (squad, team totals, speed). There is no "View all assignments" button; the Tasks tab is the list. The Performance screen never shows zero-state numbers while loading or unavailable: it shows a progress indicator or an `AppStateView` with Retry. The global `TextButton` theme has a 48x48 minimum.
- **Crew map:** turn-by-turn directions come from the backend `GET /api/routing/directions?from=lng,lat&to=lng,lat` (`OSRM_BASE_URL`, default the public demo server for development only; self-host for production). The app never calls a public router directly. Routes use `AppColors.linkDark` on dark tiles and `primaryDark` on light tiles. The depot pin and FABs are at least 48dp (no `mini` FABs). "Exit navigation" and "Start next job" share the body/w600 button style. Text on primary blue is white. "View on Map" on a report passes `?lat=&lng=` and the map opens centered there at zoom 17.
- **Crew reports and tasks:** report cards in the task are fully tappable (card tap only; no footer link, no per-card completion menu). Completion is one flow: the task-level outcome buttons and the report detail screen. The task and report routes share `_crewReportDetail`; the pending-sync chip is the shared `FcPendingSyncBadge`/`FcSyncChip` (amber uses dark 12sp text). Task cards are separated by one 16dp gap only. Photo delete targets are 48dp. Detail load failures use `AppStateView` with Retry (no raw error text). Copy says up to 5 photos can be added.
- **Crew reports filtering:** Tasks (squad jobs) and Reports (individual incidents) are different tabs. `FcReportsFilterBar` owns search, status, type, validation and response deadline; Reset appears when any of them is active and clears the search text.
- **Sync preferences** live only in Sync Center (`FcSyncPreferencesCard`). Prepare Offline links there. Sync Center refreshes by pull-to-refresh plus inline Retry on errors (no extra bottom refresh button).

## UI state and feedback matrix

| State | What the UI should communicate | Required behavior |
| --- | --- | --- |
| First load | Data is being requested | Name what is loading; keep navigation usable and avoid a false empty result. |
| Refresh / new-area search | Existing data remains useful while a request runs | Preserve content/camera and distinguish old scope from pending scope. |
| Loaded empty | Request succeeded, no matching records | Explain scope/filter and offer only applicable recovery or creation actions. |
| First-load failure | Data could not be obtained | Show a persistent explanation and working retry/access recovery. |
| Refresh failure / stale data | Last loaded data is still displayed | Identify staleness/failure; do not erase useful data or announce success. |
| Unavailable value | A particular field/count/route is unknown | Say unavailable; do not substitute zero, “synced,” or a completed state. |
| Permission denied | OS/app permission prevents the requested action | Explain the blocked action, retain alternatives, offer settings when supported. |
| Confirming | User is reviewing a consequential choice | Keep review separate from saving; do not show uploading progress yet. |
| Submitting / saving | Request is in flight | Disable duplicate activation and name the action; preserve inputs. |
| Local queued outcome | Device holds pending work | Identify local scope and actual sync policy; avoid server-success wording. |
| Server success / partial success | Returned server outcome | Reflect acknowledged records and remaining failures separately. |
| Unauthorized / expired | Current access/session cannot continue | Use existing account recovery and role routing; do not leak another role's data. |

Snackbars may announce brief outcomes, but persistent failures, map scope, pending sync, and recoverable field errors need an enduring visible home. Announce meaningful asynchronous changes without turning every map camera movement into a screen-reader announcement.

## Agent acceptance checklist and maintenance

Before calling a UI task complete:

1. State the affected platform, role, screen, and shared callers. Confirm the change did not accidentally substitute another role's map, shell, or report dataset.
2. Compare the result with the relevant contract section, existing tokens, and actual supported actions. Update this document if the accepted interaction changes.
3. Check initial loading, valid empty, loaded, refresh, failure/retry, stale data, long content, and permission states relevant to the task. For crew work include queued, partial, and server outcomes.
4. Check both themes, 320dp narrow phones, ordinary phone width, short landscape, a wider/tablet layout where supported, 2× text, keyboard visibility, and bottom safe-area/navigation overlap. Use the existing 320×480, 320×700, 700×360, and 768×900 map fixtures as concrete starting cases, not a guarantee of all devices.
5. Verify 48dp minimum interactions, named icon controls, visible focus/keyboard activation, readable contrast, semantic selected states/headings, and no clipped actions. Preserve reduced-motion behavior where supported.
6. Run the focused existing tests for changed behavior and analysis appropriate to the change. Inspect a representative rendered result when the UI changes. Report actual passes, failures, and skipped/device-only checks separately.
7. Keep release status in the backlog. A screenshot, mocked-service test, successful compile, or route constant does not alone prove live server/device acceptance.

### Existing verification entry points

Run commands from `ecopin_app/`. These are relevant suites, not a requirement to run every suite for a documentation-only edit.

| Change area | Existing checks |
| --- | --- |
| Shared theme/type/actions | `test/ui/theme_typography_test.dart`, `test/ui/shared_controls_test.dart` |
| Shells and role destinations | `test/ui/role_navigation_test.dart`, `test/ui/citizen_navigation_test.dart`, `test/ui/admin_routes_test.dart` |
| Citizen public map | `test/reports/public_map_screen_test.dart`, `test/reports/report_map_status_test.dart`, `test/reports/public_report_map_test.dart`, `test/ui/public_map_ui_test.dart` |
| Reporting and local evidence | `test/ui/create_report_flow_test.dart`, `test/ui/local_media_test.dart`, `test/ui/offline_report_receipt_test.dart` |
| Place search and voice | `test/ui/location_search_controller_test.dart`, `test/ui/location_search_overlay_test.dart`, `test/ui/location_voice_adapter_test.dart` |
| Crew dashboard/offline/sync | `test/ui/crew_dashboard_ui_test.dart`, `test/ui/crew_offline_ui_test.dart`, `test/ui/crew_sync_settings_test.dart` |
| Account and notifications | `test/ui/auth_layout_test.dart`, `test/ui/required_password_change_test.dart`, `test/ui/notifications_test.dart` |
| Native administrator work | `test/ui/admin_users_test.dart`, `test/ui/admin_settings_test.dart`, `test/ui/admin_audit_test.dart` |

For example, a citizen viewport change can be checked with `flutter test test/reports/public_map_screen_test.dart test/reports/report_map_status_test.dart`, followed by appropriate analysis and rendered inspection. Documentation-only changes require checking links, source references, and contradictions rather than claiming a new runtime verification.

Physical GPS/microphone behavior, Android permissions/settings, real connectivity/storage failures, background uploads, push/deep links, gesture navigation, and TalkBack remain explicit device acceptance when affected. Do not mark them verified from synthetic tests.

### Keeping this contract useful

- Update the relevant section when an approved design behavior changes; remove contradictory old wording in the same edit.
- Keep native guidance here and web guidance in the web contract. Link shared background instead of copying web-only instructions.
- Preserve established requirements when expanding the document. Label new intended rules and known implementation gaps honestly.
- Keep paths and test references real. Move/rename references with their owning files; avoid line-number references that immediately drift.
- Do not use this document to add permissions, unsupported capabilities, backend state transitions, or dependencies. Those need their own authorized implementation scope.
- Do not append claims such as “all screens modernized” or “fully tested” without evidence covering that claim.

### Citizen self-service account deletion

Only a profile with the explicit `citizen` role may show or invoke Delete Account. Officer, field-crew, administrator, missing-profile and unknown-role states have no self-service deletion action; the server independently enforces this rule. The scrollable dialog explains permanence and report anonymization, requires the exact phrase `I confirm`, and enables its centered full-width destructive button only after a match. Cancel or dismiss performs no request; reopening clears the phrase. Use stacked actions at small widths and enlarged text.

The authorized server request revokes sessions before anonymizing reports or deleting account data. Stop without deleting when revocation fails. Clear the mobile session after success and after server-reported post-revocation failure; show failures honestly and direct the user to sign in again or contact support. Existing multi-step deletion can partially complete if a downstream service fails; it is not an atomic database transaction.

### Citizen public Map / List browsing

The citizen Map destination offers Map and List views; My Reports remains the user's own submissions. Only the citizen public-discovery screen gains this switch. Preserve the map instance/camera, heatmap choice, loaded results and list scroll position when switching. Fetch the List lazily on first selection; list browsing spans all public areas independently of the map viewport, newest first, with bounded pages and explicit Load more. Describe that scope in the UI.

List cards show public title, concern type, response status, submission date and approximate-location disclosure, and open the existing public preview. Reuse the explicit safe fields from `public_reports`; no reporter identity, staff enrichment or private evidence. Use an icon fallback rather than inventing a gallery photo path. Include initial loading, valid empty, retry, refreshing with retained cards, and load-more failure with retained cards. Refresh starts a new list; deduplicate reports across pages. Stacked cards and wrapping text must work in both themes at narrow width/enlarged text. This is a List alternative; web gallery filters and image parity are outside this increment.

### Report location picker and detail maps

Create Report and the shared Report Details map default to zoom 17 for a closer street-level view. Both use the 56 by 64 pointed `ReportPinFrame` footprint with `Alignment.topCenter`, placing the visible bottom tip exactly on the selected/stored coordinate. Do not center the whole pin silhouette on that point. Creation uses a primary-color crosshair/check pin identifying the selected location; submitted report detail uses the shared status/concern marker. Keep selection explicit (tap or Use this map center); panning alone does not change the saved location. Preserve supplied coordinates and any public approximation; closer zoom does not improve GPS accuracy. Detail maps remain noninteractive. Location/date text wraps alongside its icon.

### Citizen My Reports filter sheet

Use the exact title `My Reports`. A named Filter reports button in the app bar replaces the horizontal status-chip strip. Its badge identifies an active status filter. Open a rounded (24dp top corners), safe-area, scrollable bottom sheet with the existing status options, an explicit Apply filters action, Reset status, and a named close action. Stage status changes locally until Apply; dismissing preserves the applied status. Reset status stages All without clearing search. Preserve search, rejected-report visibility, provider ownership and pagination rules; applying a status starts from the first displayed page. Keep sheet choices and actions readable at 320dp with enlarged text in both themes.

### Citizen profile navigation avatar and map credits

The citizen Profile destination uses the current profile's uploaded `avatar_url` as a circular foreground image, with first/last-name initials underneath while loading, when no image exists, or on image failure. Trim names/URLs; a single name uses one initial and an unavailable name uses `?`. Subscribe to the existing profile provider so profile edits/uploads refresh the navigation avatar. Preserve the Profile label, selected indicator, destination and 48dp action target. Map legend credit buttons center each wrapped text line, including OpenStreetMap and CARTO, in both themes and at enlarged text sizes.

### Citizen navbar silhouette on plain pages

The citizen shell provides a subtly tinted light page canvas, derived from the existing divider palette, with matching page app bars; the navigation surface remains white. Dark mode retains the existing background/surface distinction. Apply this scope consistently to Reports, Alerts and Profile rather than changing the global app theme. The 12dp top corners, 72dp surface backing and 56dp raised Report action remain unchanged. Keep the space beside the raised action transparent so the page canvas or map is visible; do not introduce a rectangular shadow band. The map fills the area behind navigation after its status footer is removed. Public List adds the inherited bottom inset to its scroll padding so final records/actions remain reachable.

### Crew evidence ownership

Task Details is a task overview, not a cleanup evidence editor. Show a wrapping title, written priority/status, readable street address, team name and member names. Never display UUID initials or raw geometry as a place. Resolve point coordinates independently, cache the address, and use a labeled coordinate fallback when unavailable.

Progress and the report list use only the task's canonical linked report IDs (including satellite/claim/embedded membership). Never fall back to every report in a cluster. Exclude rows assigned to a different task. Show missing linked-record counts and block completion until all linked records are present and handled. Label progress as reports handled, not sites physically cleaned. Local completion remains pending sync until acknowledged.

Remove task-level Before/After controls and the task-wide Unable to Work This Site action, including standalone tasks. Preserve existing stored/queued task media without exposing new task-photo mutations. Cleanup evidence and outcomes belong to each report. The citizen gallery displays authorized citizen evidence for linked reports; accept the service's canonical url field and legacy keys. Show loading, unavailable with retry, and confirmed-empty states distinctly. Fetch in bounded batches without polling. Report cards offer All/Open/Handled filters, written statuses and navigation back to their report details. Refresh after returning from a report.

### Offline preparation request and receipt contract

Prepare offline downloads records explicitly; its byte estimate excludes image/video binaries and map tiles and does not predict request latency. Fetch only assigned task report IDs in batches of at most 100, validate returned IDs on-device, paginate cluster-only assignments, and use strict evidence batches of at most 10. Never fetch an unfiltered report list as reference data. Pace preparation requests at least 250ms apart, enforce a 20-second whole-request cancellation deadline, allow only one preparation run, and stop later network steps on 401/403/429. Honor Retry-After (seconds or HTTP date), with a minimum 60-second cooldown; no automatic polling/retry loop. Authentication refresh retries each failed request once.

Show actual cached task/report/evidence/note/route counts and an expandable Saved on this device inventory of task/report titles. Persist the section results, counts, inventory, owner and attempt phase; reopening must retain missing-data warnings, not turn partial preparation into verified success. An unreadable/legacy receipt is unverified; another account's inventory must not be restored. Cache write failures must surface as preparation failures, and fetching server task/report records must preserve locally modified records. Bundled reference fallbacks are labeled available in the app rather than downloaded. Preparation downloads metadata only; images, videos and map tiles still require a connection unless independently cached.


### Crew Route availability

An active route is an approved published route linked to unfinished assigned tasks, not only a route from the newest approved run across all crews, and not necessarily a route created today. Preserve crew membership authorization. Select a matching route from unfinished, non-held, non-locally-completed tasks in the established in-progress/priority order, skipping missing historical links. Remove settled report stops and completed/cancelled/held task stops. A task assignment without a published route remains accessible through Tasks; do not fabricate a route or imply approval is pending. Distinguish route loading failures from a verified empty result, and keep a Refresh route action. No GPS/navigation calculations or scheduling capacities are changed by this lookup.

### Crew Route order switch

The Route screen's bottom action card holds a two-segment **Priority | Nearest** switch directly above **Start next job**, within thumb reach and next to the button it controls. Priority keeps the published route order (most urgent first) and is the default. Nearest picks the unfinished, non-held task whose stop is closest to the crew's current GPS position, measured as straight-line distance and labeled that way; it is not a road distance or ETA. Without a GPS fix, or when no stop has coordinates, Nearest falls back to the published order and says it is waiting for GPS. A one-line **Next:** summary names the task the button will start, announced as a live region. The switch hides while a job is being navigated; the active destination never changes mid-navigation. The choice is remembered on this device (`fc_route_order`); if it cannot be saved it still applies for the session. Map pin numbers keep showing the published stop sequence in both modes. The map action buttons stack above the card so they follow its height. The selection logic lives in `lib/features/field_crew/presentation/controllers/fc_route_order.dart`; checks are in `test/ui/crew_route_order_test.dart` and `test/ui/crew_route_navigation_ui_test.dart`.

### Crew Route guidance and offline behavior

Start next job requests HTTPS road geometry and maneuvers for the selected task, with a three-second whole-request cancellation deadline. Require at least two distinct path points and valid maneuver coordinates. Display readable instructions and retain real turn steps for progression/voice guidance. Initialize iOS-specific speech options only on iOS; speech failures must not prevent visual guidance.

After a successful request, save the last destination's geometry and maneuvers under the signed-in account, route ID, task ID and destination. Say whether directions were saved successfully. This is a bounded last-destination cache, not an offline street-routing engine or a promise that Prepare offline downloads every destination's maneuvers or map tiles. When using saved turns, label the state Saved directions and explain that live rerouting is unavailable. Check the cached destination still matches the current task; project current GPS onto the saved road segments and keep upcoming turns only. If the crew is over 100m away from that path, ask them to reconnect instead of drawing a fabricated straight-line connection.

If only published waypoint geometry is available, use the selected destination's leg, not every earlier task. Require a usable path and label it Saved route preview with explicit no-turn-guidance copy and an Exit preview action. A stop coordinate alone cannot start guidance. Do not retain old steps or a full-route ETA from an earlier destination; show unavailable time as an em dash. Missing geometry keeps the Route screen usable and shows a reconnect message. Overview displays real available route-leg polylines without joining gaps through invented roads.

Stops, estimated time and distance use semantic on-surface colors in both themes, equal-width columns and wrapping labels. Instructions use white text on civic blue. Keep the main Start/Exit action 16dp above the owning screen's bottom edge: the field-crew shell already reserves navbar space, so do not add a second fixed 130dp gap. Locate/voice actions sit above that card; hide voice controls for geometry-only previews. Use sentence-case labels and 48dp-or-larger actions. Navigation does not complete tasks or modify assignments.


### Crew cannot-work dialog dismissal

Cancel, barrier dismissal and system Back close Unable to Work This Site without queuing feedback or holding the task. Keep text-editing resources alive until the dialog exit transition and overlay removal finish; a navigation pop result alone does not mean its text fields are unmounted. A delayed photo picker result must not rebuild a dismissed dialog. Opening a new dialog starts with fresh notes. Keep long reason choices within the available dialog width.


### Report arrival evidence and cleanup outcomes

For acknowledged reports assigned to the crew, allow After Photos without a Before photo to document a site already clear on arrival. Show explicit guidance: normal cleanup requires Before before work and After once finished; an already-clear observation needs one current photo in After, then Already clear on arrival in Task Details. Never instruct users to duplicate a photo into both slots or claim cleanup credit for a clear-on-arrival observation. Missing-evidence outcome actions show contextual instructions and Open report navigation, not a dead-end toast. Cleaned outcomes require both report photo slots; already-clear observations require After only. Returning from report details refreshes task data.


### Crew response action ownership

Keep Mark as Acknowledged on new reports. Once acknowledged, remove the manual Mark as Responded action entirely and direct the crew to Before photo evidence. Responded must follow the authoritative photo workflow, not a second manual status button. Preserve map navigation and existing completion/photo guards.


### Crew report stage and list contract

Acknowledgement is a stage update, not a legacy status transition to in_progress. Resolve the action from both stage and terminal status: an unresolved report with acknowledged stage must never repeat Mark as Acknowledged. Before evidence records Responded locally pending sync and commits stage responded/status in_progress atomically through set_report_photo on the server. Do not expose manual Responded. Refresh must await authoritative report data when there are no pending local edits.

The crew Reports page contains exact task-linked reports only, including canonical satellite/claim links. Sharing a cluster does not grant list membership. Exclude rejected response and validation states, including cached records. Report filter sheets must scroll as a whole, protect the bottom system inset, use compact title spacing and white selected checkmarks; do not offer rejected validation as a crew work filter.


### Citizen evidence viewing in crew report details

Citizen evidence remains inside the app. Photos open the existing full-screen zoomable viewer with normal Back navigation; do not launch Cloudinary URLs externally. Videos have an explicit play affordance and open an in-app player with play/pause, loading/error handling and controller disposal on exit. Reuse the citizen report player rather than maintaining a second playback implementation. Empty, invalid or unavailable evidence shows a media placeholder and truthful refresh guidance, never a claim that the citizen submitted nothing. Preserve evidence-error distinction and authorization-aware photo delivery.


### Crew report Before photo capacity

Allow up to five Before photos per report, retaining the existing one-After-photo limit. Show the current count and remaining capacity; render each Before photo with its own preview, sync state and delete action. Existing single Before photos count toward five. Persist collection IDs and metadata through server, cache and offline sync; never overwrite the prior Before photo when adding another. Preserve the legacy first-photo URL for compatibility and completion guards. Enforce capacity under the report lock on the server, reject duplicate/replayed uploads safely, and delete only the selected photo. Pending removals free local capacity; synchronize removals before replacement uploads. Photo-section headings and requirement/remaining-slot labels wrap naturally on narrow screens and with large text.


### Crew automatic sync and queue indicators

Every crew report/task/photo/outcome edit saves locally first. In Automatic mode, new outbox payloads and photo upload/removal intents wake one mode-aware sync engine after a 150ms burst debounce, on an allowed connection. Keep the service active across settings changes, await saved preferences before sending, serialize runs and schedule one follow-up for edits made during an active run. Retry counters, in-flight transitions and queue removals do not count as new edits and must not create a polling loop. Reconnect, transitions from a blocked transport to an allowed Wi-Fi/mobile transport, and periodic recovery remain available. Manual Commit requires an explicit commit; Offline Only sends nothing. Repositories must not bypass this gate with independent REST writes.

Display Syncing while sending and reserve Pending Sync wording for manual/offline modes; automatic unsent work is Sync queued until sending or a reported failure. Never hide work merely because an earlier run succeeded. Drive dashboard/detail counts from live local queue changes, including photo-only intents; refresh open details after a run. Failed/exhausted uploads stay on the device and remain attention states. Removing the last unsent photo also removes its orphaned upload queue marker. Network restrictions and server errors can still prevent automatic delivery; do not claim acknowledgement until confirmed.

Crew note responses reconcile into the notes cache by their saved local-note ID. Never apply a note server record to the report snapshot or replace the report identity.

### Crew Route pins and previews

Crew Route uses the shared pointed ReportPinFrame (56 x 64dp, Alignment.topCenter). Task stops retain their route sequence and layered task badge; report pins show actual response status and concern rather than validation approval. Nearby task, report and depot markers group visually; counts describe route pins, not operational cluster membership. Preserve zoom and circular expansion for coincident coordinates without changing stored locations. Task previews and report previews use semantic theme colors, scroll within a safe-area bottom sheet, and open the existing task-scoped detail routes. Preview actions never mark a task complete; completion remains in Task Details.

### Crew Sync Center failure explanations

Show persisted per-item failure reasons for response logs, report/task changes, and Before/After photos, with entity references and attempt counts. Preserve useful server messages without exposing the transport stack or raw response body. A paused queue is not a successful sync. Explicit connection-failure retry reset must preserve operation IDs and payloads and exclude terminal rejections, authorization failures and version conflicts. Photo retry reset remains separate. Missing server photo schema is a temporary server-update failure; keep the local photo queued.

Count one photo failure per actual upload attempt. A permanent rejection pauses automatic retries independently of the counter. For older permanent failures whose counter was artificially exhausted, say that the attempt count is unavailable. Keep safe server request references with the failure reason. Distinguish accepted changes from photo failures in last-run feedback, including skipped paused photos; a successful response-log write must not be described as failed because another queued photo failed.

### Staff profile settings - 23 October 2026

Officer Account uses the shared profile screen. Share Personal Information and self-deletion are citizen-only. Officer Account includes avatar upload/removal, editable name, read-only email and assigned role, Light/Dark/System preference, password change, and logout. The browser Command Center tutorial remains web-specific.

### Citizen floating map chrome - 23 October 2026

Citizen discovery uses a full map canvas with a safe-area floating Map/List and area-status toolbar. The selected view uses civic blue; the area indicator distinguishes loading, failure and loaded results with readable text. Search remains separate above a 48dp-per-action dock for heatmap, locate and legend. Tinted pin faces retain category/status icons, selection rings and full cluster counts. The existing preview sheet retains public-only report navigation and a quiet privacy notice. Citizen navigation is unchanged by this layout revision.

### Report sharing feedback - 23 October 2026

The citizen report Share action immediately shows an accessible progress indicator and disables repeated activation until preparation and the native share request finish. Restore it after completion or failure; leaving the screen must not trigger state updates on a disposed widget. Render the image card in a background isolate so the loading animation stays responsive.

### Citizen content and map chrome refinement - 23 October 2026

Use compact map count copy (for example, "4 reports") with the full public-area scope in accessibility text. Truncated results still disclose "Newest 200" and "Zoom in"; refresh failures retain the prior-results explanation. Place status-bar safe-area padding outside the toolbar surface in List view. Public discovery keeps a compact all-areas/newest-first header and the same 16dp card padding, 18dp titles, 16dp (`radiusCard`) corners and semantic boundaries as My Reports and Alerts.

Citizen Reports and Alerts scroll beneath the raised navigation silhouette rather than stopping at the navbar's rectangular bounds. Reserve the actual bottom inset as scroll-content padding so the final item remains reachable. Keep the existing navbar shape, actions and destinations. Alerts uses the citizen tab name as its page title; staff notification pages retain Notifications.

### Response deadline visibility - 27 October 2026

Citizen My Reports, public discovery list/preview, shared report details and crew report/task views show a separate response-deadline indicator from server `deadline_at` and `sla_started_at`. The final 20% of the actual SLA window is approaching; deadline equality is overdue. Assignment/cluster membership must not hide elapsed time. Terminal/rejected reports stop the running indicator. Unknown timestamps do not invent deadlines. Details identify the response target without promising cleanup completion. Crew filters distinguish At risk and Overdue; task summaries describe the earliest known linked report deadline. Cached timestamps survive offline storage, while report status still requires refresh/sync. The signed-out public website also exposes these indicators; this does not change native authentication. See `../ecopin-web/docs/response-deadlines.md` for deployment order and validation limits.

### PDT-05 official coordination contacts (29 October 2026)

Profile and citizen/officer Report Details expose Official contacts, opening it on the root navigator above all role navigation bars with bottom safe-area spacing, using the shared CMS-backed screen in `lib/shared/support/official_contacts_screen.dart`. Show sourced SWMO trunkline/extension, email and separate emergency hotline without report/profile network dependencies. Load the admin-published contact configuration from the public CMS endpoint on opening; retain bundled office contacts with an explicit fallback notice and Retry contacts when unavailable. Honor optional extension/email and show the published verification date. Opening the dialer/email must not submit a report or claim a dispatch. Retain selectable details after a launch failure and support large text in both themes. Native account routes/role ownership are preserved. Validation and release limits: `../docs/official-contact-channel.md`.


### PDT-04: on-site urgency observations (29 October 2026)

Assigned crew use task-scoped Report Details alongside Before/After photos and completion to record Urgency observed, Conditions differ, or Unable to verify, with required observed conditions. Save through the existing local note cache and additive outbox; preserve sync modes, failures and stable retry IDs. Bind observer account and task/report claim generations. Do not add a compulsory completion step, a crew penalty control, or an automatic trust/urgency transition.

Officer Report Details shows acknowledged observations, available photo snapshots and separate reasoned review. Reuse the private in-app image viewer. Marking reviewed does not score a citizen or prove a false claim. Keep the distinct, deliberate desk trust decision and its punitive confirmation. Source snapshot time is server acceptance; later/missing photo uploads must not be presented as absent citizen evidence. Forms wrap at narrow widths and large text in both themes. Evidence and rollout limits: `../ecopin_backend_node/docs/crew-urgency-observations.md`.


### PDT-12: crew on-site investigation

Task Details and task-scoped Report Details show automatic 5 m arrival, measured GPS accuracy and a five-minute continuous investigation indicator for each incident; standalone tasks use their own pin. Keep acknowledgement/photos available, while cleanup outcomes and task completion require the investigation gate in addition to existing evidence checks. Leaving, unreliable/stale GPS, interruptions or backgrounding reset unfinished dwell. Completed device evidence can restore only for the same account/assignment/incident pins/claims; current presence always needs fresh GPS. Show persistent permission/service recovery and missing-pin guidance. Do not describe device GPS as guaranteed or server-attested physical presence. Scope, release limits and verification: `docs/crew-investigation.md`.


### PDT-20: report-level identity choice

Citizen Create Report Review includes “Hide my identity”. Its per-report override takes precedence over account-wide name-disclosure consent without changing that consent. Preserve the choice through offline drafts, retries and resubmission. Hiding applies to public, officer, crew and admin output; private ownership still supports My reports, notifications and trust enforcement. Copy explains that report text/photos remain visible and may identify the author if they include personal details. Keep the control accessible, available in both themes and readable at 320px. Database/API protection is authoritative; UI masking alone does not implement this contract. Prototype/review/rollout status is recorded in `../UI_UPDATE_BACKLOG.md` under PDT-20.

Officer operational maps must retain hidden reports through the protected `reports_view`, with identity fields masked. The current feed loads paginated rows immediately and refreshes every 15 seconds while subscribed; disposal cancels polling, and failures offer Retry. Raw `reports` CDC cannot substitute for this feed because identity-protected rows are deliberately unavailable to other accounts. Citizen public-map and own-report sources keep their existing scopes.

### PDT-13: required cleanup proof

Field Crew remains mobile only and Officer verification remains on web. Capture different Before and After photos for physical cleanup and require action notes before queuing outcomes or completion. Keep existing investigation, photo sync and assignment/version gates; saved locally is not server acceptance. Already-clear-on-arrival is an observation and must not require a fabricated Before photo or claim cleanup credit. New originals use authenticated delivery. Citizen Report Details shows only the officer-approved, privacy-reviewed public copies, with written Before/After labels, public action notes and completion/verification times. Missing/error proof has a truthful state and retry without falling back to originals. Implementation, review reconciliation, legacy-image limits and coordinated rollout: ../ecopin_backend_node/docs/cleanup-proof.md; evidence/status: ../UI_UPDATE_BACKLOG.md.

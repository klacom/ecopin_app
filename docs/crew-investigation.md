# PDT-12: crew arrival and investigation gate

Implemented locally, 29 October 2026. Scope: Flutter field-crew Task Details, task-scoped Report Details, local outcomes and completion receipts. No deployment or live database change was made.

## Rules

- Each linked incident requires its own investigation at that report's coordinates (confirmed by the owner). Standalone tasks use their task pin. A task/cluster centroid never substitutes for missing incident coordinates.
- Arrival is automatic when a fresh position is within **5.0 metres**. Distance comparisons retain fractional metres; 5.1 m is outside. Every credited fix must be non-mock with finite coordinates and reported horizontal accuracy greater than zero and at most 5 m.
- Five continuous minutes are measured with a monotonic stopwatch between accepted samples, not by subtracting wall-clock timestamps or waiting after a single fix. The boundary at 300 seconds is inclusive. Position age must be at most 10 seconds, with at most two seconds of future tolerance. Repeated/out-of-order fixes are rejected. Gaps exceeding 15 seconds, inconsistent sensor/monotonic intervals, unreliable positions, leaving the radius, or app backgrounding reset incomplete dwell.
- A one-second watchdog invalidates stalled observations. The dedicated position stream requests best-for-navigation accuracy, zero movement filter and a 15-second timeout. No last-known-position fallback is used. Existing general map/location behavior is unchanged. Permission/service failures expose Retry, GPS settings and permission settings.
- Task Details and task-scoped Report Details share the active task's session. GPS runs while its screen subscription exists and the app is foregrounded; leaving the task disposes it. A completed investigation is retained in device preferences across navigation/restarts, bound to account, task/assignment generation, exact target coordinates, incident set and report claim generation. Partial timers are never restored. A changed scope/pin/claim invalidates the old snapshot. Restoring completed evidence does not restore current presence.
- Recording an incident cleanup/already-clear outcome requires both its completed investigation and a current accepted fix at that incident. The guard runs again after confirmation, immediately before enqueueing. Existing photo and assignment checks still apply. Legacy report-completion actions are also gated; acknowledgement and photo capture remain available before investigation completion.
- Task completion requires all linked investigations plus the existing handled-report checks. Bundle completion can occur after visiting the separate incidents; it does not require simultaneous presence at all pins. Standalone completion additionally requires a current in-radius fix.
- Receipts record target, crew, task, assignment/claim generation, arrival/completion time, dwell duration, accepted sample count and maximum reported accuracy. Report outcomes and task completions retain them in existing offline outbox JSON. No database schema or new runtime dependency was needed. Completed-evidence storage failures remain visible; the current session can still save its outcome.

## Limits and release acceptance

This is a **mobile workflow gate and device GPS evidence**, not server-attested or tamper-proof proof of presence. Client-supplied GPS can be manipulated beyond the platform's mock flag. Reported 5 m accuracy does not guarantee the true position is within 5 m, and urban GPS can prevent legitimate crews from qualifying. No automatic radius widening, bypass or manual override was added. Officers must correct inaccurate/missing incident pins; crews can retry GPS/permissions.

The shared backend was not changed to independently accumulate dwell or reject other clients/older app versions. Existing sync transports forward additive JSON payloads; authoritative server retention/adjudication of investigation evidence was not established by this task. If server-enforced anti-fraud is required, it needs a separate server policy and a compatibility rollout for older clients. Do not present this feature as guaranteeing physical presence or investigation quality.

Completed snapshots contain operational coordinates in this app's device preferences and are scoped to the recorded crew account; they are never reused for another account. Pending outbox evidence follows the existing sync policy. Review device retention/sign-out data policy before release if indefinite local assignment receipts are unsuitable.

Physical Android/iOS GPS behavior, denied/approximate permission recovery, stationary update cadence, urban drift, background/resume and five-minute outdoor acceptance remain **unverified on a real device**. No APK or store release was produced.

## Verification

49 focused tests pass: 27 new timing/session/local-DB checks plus existing task data, evidence and urgency regressions. They cover drive-bys, fractional metre exclusion, mock/stale/replayed/poor fixes, missing samples, clock changes, independent incidents, account/assignment/coordinate/claim invalidation, restored completed receipts, partial-reset behavior, and local outbox evidence. The completion integration verifies that a rejected early attempt makes neither a local task status change nor an outbox write.

The broad regression run passed 582 tests and found one test-double compilation mismatch after the additive repository parameter. Its signature was updated; all six tests in that file pass on the focused rerun. The final focused run includes those six. No assertions or tests were removed/skipped to obtain passing results. Logs: `.ui-review/pdt12-full-tests.log`, `.ui-review/pdt12-focused-tests.log`.

Light/dark screenshots at 320px and 2x text were rendered and inspected: `.ui-review/investigation-light.png`, `.ui-review/investigation-dark.png`. Scoped Dart analysis reports no issues.

[Geolocator documentation](https://pub.dev/packages/geolocator) defines stream settings and location permissions. Requesting high accuracy is not a promise of a particular measured accuracy or update cadence.

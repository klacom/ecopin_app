# Image Location Verification Plan: Ensuring Photo Authenticity

## 1. Executive Summary (In Plain English)

To make sure a photo submitted in an EcoPin report was actually taken at the physical location being reported, the system uses a **"Digital Stamp"** process inspired by field-verification apps like TimeMark:

1. **Live Camera Capture**: The user snaps a photo directly through the app's camera rather than picking an unverified picture from their phone's photo album.
2. **Instant Location Stamp**: At the exact fraction of a second the shutter clicks, the phone's GPS records the device's coordinates, timestamp, accuracy, and checks if fake GPS apps are running.
3. **Pin Comparison**: The user points to the concern's spot on the map.
4. **Distance Check**: The app compares where the camera was standing versus where the pin was dropped.
5. **Trust Classification**: If the photo was taken within ~50–100 meters of the pin, it is marked as **Verified On-Site**. If it is miles away or from an unknown origin, it is flagged for officer review.
6. **Visual Proof (TimeMark-Style)**: The photo itself receives a burned-in visual banner showing the Pasig address, GPS coordinates, and timestamp.
7. **Post-MVP Social Loop (Follow-Up)**: Once the core flow is fully functional, verified reports can generate a shareable social card with a QR code for Facebook/social media so citizens can report concerns too.

---

## 2. High-Level Flow Diagram

```text
[Citizen taps "Take Photo"]
          │
          ▼
[App captures photo + samples Hardware GPS simultaneously]
          │
          ├── GPS Coordinates (Lat/Lng)
          ├── GPS Accuracy (± meters)
          ├── Network-Synced Timestamp
          └── Mock Location Check (isMocked: true/false)
          │
          ▼
[Citizen selects concern location pin on Map]
          │
          ▼
[System calculates distance: Camera GPS ⟷ Map Pin]
          │
   ┌──────┴────────────────────────┬────────────────────────┐
   ▼                               ▼                        ▼
[Distance ≤ 75m + buffer]      [Distance 75m - 300m]    [Distance > 300m or Fake GPS]
   │                               │                        │
🟢 VERIFIED ON-SITE            🟡 UNVERIFIED NEARBY     🔴 LOCATION MISMATCH / FLAGGED
   │                               │                        │
Priority Dispatch              Standard Review          Officer Triage Required
```

---

## 3. Step-by-Step Architecture

### Step 1: Mobile App Capture (`ecopin_app`)
* **Live Camera Priority**: Default report creation to in-app camera capture.
* **Instant GPS Telemetry**: Use Flutter's `geolocator` with `LocationAccuracy.high` when the shutter is pressed.
* **Anti-Spoofing Check**: Query `position.isMocked`. If an Android user is running a "Fake GPS" app, record `is_mocked = true`.
* **Metadata Payload**: Attach the following payload along with the image upload:
  ```json
  {
    "photo_source": "camera",
    "captured_at": "2026-10-16T00:15:00Z",
    "capture_lat": 14.576390,
    "capture_lng": 121.085110,
    "accuracy_meters": 12.5,
    "is_mocked": false
  }
  ```

### Step 2: Distance Calculation (Haversine Formula)
The distance $\Delta d$ between the pinned report coordinates $(Lat_{pin}, Lon_{pin})$ and the photo capture coordinates $(Lat_{cam}, Lon_{cam})$ is evaluated:

$$\text{Tolerance Radius} = 75\text{m} + \text{Device Accuracy Buffer}$$

* If $\Delta d \le \text{Tolerance Radius}$, the submission is verified on-site.
* If user picks from Gallery, check image EXIF data for GPS tags as a secondary fallback. If EXIF is stripped or missing, tag as `UNVERIFIED_GALLERY`.

### Step 3: Backend Verification & Trust Classification (`ecopin_backend_node`)
When the report reaches the backend:
1. Re-compute the distance server-side to prevent client tampering.
2. Check duplicate image fingerprints (perceptual hashing via `ecopin_image_validation`) to prevent re-using old photos from different areas.
3. Assign a `location_verification_status` to the report database record.

### Step 4: TimeMark-Style Visual Watermark (Burn-in)
Before final upload, the app stamps the photo with a permanent semi-transparent banner:
```text
┌────────────────────────────────────────────────────────┐
│                                                        │
│               [ Captured Photo Content ]               │
│                                                        │
├────────────────────────────────────────────────────────┤
│ 🛡️ EcoPin Verified On-Site                             │
│ 📍 Caruncho Ave, Brgy. San Nicolas, Pasig City         │
│ 🌐 14.57639° N, 121.08511° E (Accuracy: ±6m)           │
│ 🕒 2026-10-16 01:15 PM PST • Pasig City CENRO          │
└────────────────────────────────────────────────────────┘
```
* **Why this matters**: Instant proof for officers in the web portal, field crew on mobile, and contract auditors without needing to inspect database tables.

---

## 4. Trust Level Matrix

| Trust Badge | Trigger Criteria | Action Taken |
| :--- | :--- | :--- |
| 🟢 **Verified On-Site** | Camera capture, distance $\le 75\text{m}$, `is_mocked == false`, timestamp fresh. | High-confidence report; proceeds straight to auto-clustering and cleanup crew assignment. |
| 🟡 **Nearby / Gallery** | Gallery upload with valid EXIF within $300\text{m}$, or camera distance between $75\text{m} - 300\text{m}$. | Standard processing; flagged with a notice explaining the slight distance difference. |
| 🔴 **Mismatch / Suspect** | Distance $> 300\text{m}$, mock GPS detected, or duplicate photo hash. | Held in a triage queue for officer review before dispatching field teams. |

---

## 5. Edge Cases & User-Friendly Solutions

1. **GPS Drift in Urban Canyons (Tall Buildings)**:
   * *Issue*: GPS can bounce off concrete buildings and be inaccurate by 30–50 meters.
   * *Solution*: Dynamic accuracy buffering: add the device's reported GPS error margin to the threshold radius.
2. **Reporting from Safety / Across the Street**:
   * *Issue*: Citizen spots hazardous waste in a canal, river, or construction site and takes a photo from 60 meters away across the road.
   * *Solution*: The 75m–100m radius gives citizens enough distance to safely snap photos without being rejected.
3. **Offline Mode**:
   * *Issue*: User has no data connection at the site.
   * *Solution*: The app captures the photo and stores the device's raw GPS and timestamp locally in SQLite. When the user connects to Wi-Fi later, the original timestamp and GPS are submitted intact.

---

## 6. Implementation Roadmap & Sequencing

> [!IMPORTANT]
> **Strict Execution Sequence**: Phases 1–3 form the core functional system and must be completed and validated first. Phase 4 (Social Sharing) is a follow-up expansion that will only begin once the verification pipeline is fully functional and stable.

### 🔷 Primary Milestone: Core Functional System (MVP)

* **Phase 1: Mobile GPS & Mock Telemetry**
  * In [create_report_screen.dart](file:///d:/Flutter/ecopin_app/lib/shared/reports/presentation/screens/create_report_screen.dart), capture GPS coordinates, accuracy, and `position.isMocked` at the moment `_pickImage(ImageSource.camera)` is clicked.
  * Pack telemetry into report creation payload.

* **Phase 2: Backend Distance & Trust Classification**
  * Update `reports` schema in database with `photo_lat`, `photo_lng`, `photo_accuracy`, `photo_captured_at`, and `location_verification_status`.
  * Implement Haversine distance validation in the report submission controller.

* **Phase 3: Visual Watermarking & UI Badging**
  * Add TimeMark-style banner drawing to the photo bytes upon capture.
  * Render trust badges (🟢 Verified, 🟡 Nearby, 🔴 Mismatch) in [report_details_body.dart](file:///d:/Flutter/ecopin_app/lib/shared/reports/presentation/widgets/report_details_widgets/report_details_body.dart) and in the `ecopin-web` officer dashboard.

---

### 🔶 Follow-Up Milestone: Direct Photo Sharing with Burned-In QR Code (Completed)

* **Feature Overview**:
  * Allows citizens to share their stamped photos directly to Facebook, Instagram Stories, Messenger, Viber, and other platforms.
  * The photo itself contains both the official verification stamp and the scannable civic QR code:
    1. **Bottom-Left**: TimeMark layout (digital clock, civic blue divider `#0052CC`, date stack, street address, and coordinates with verified badge).
    2. **Bottom-Right**: High-contrast, scannable **QR Code** card with `"SCAN TO REPORT"` caption in Civic Blue.
    3. The QR code links directly to EcoPin (`https://ecopin-web.vercel.app/downloads` / `/reports/:id`) so anyone viewing the photo on social media can scan it to track the report or download the app and report issues in their community.
* **Implementation Stack**:
  * **Flutter Mobile (`ecopin_app`)**:
    * Updated [photo_verification_service.dart](file:///d:/Flutter/ecopin_app/lib/core/services/photo_verification_service.dart) to generate and burn the QR matrix directly onto the photo pixels using `package:qr/qr.dart`.
    * Implemented [report_share_helper.dart](file:///d:/Flutter/ecopin_app/lib/shared/reports/presentation/widgets/report_details_widgets/report_share_helper.dart) for instant photo sharing via `Share.shareXFiles`.
    * Added direct Share action to [report_details_screen.dart](file:///d:/Flutter/ecopin_app/lib/shared/reports/presentation/screens/report_details_screen.dart).
  * **Backend (`ecopin_backend_node`)**:
    * Enabled `optionalAuthenticate` on `GET /api/reports/:id` in [report.routes.js](file:///d:/ecopin_backend_node/src/routes/report.routes.js) for public QR scanners.
  * **Web Portal (`ecopin-web`)**:
    * Created public report landing page at [app/reports/[id]/page.js](file:///c:/Users/PLPASIG/Desktop/ecopin-web/app/reports/%5Bid%5D/page.js) with verified badge, stamped photo, report details, and app download links.



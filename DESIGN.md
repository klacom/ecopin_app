# Ecopin Design System: Premium Sleek & Neon (Mobile-First)

This document outlines the core design language, aesthetic principles, and technical implementation details for the Ecopin app redesign. This system replaces the previous "Neo-Brutalist" style with a highly polished, sleek, and premium mobile-first aesthetic.

## 1. Core Philosophy
The design language focuses on creating a high-end, smooth, and highly legible user experience. It uses a dark mode foundation combined with striking, vibrant neon accents to draw attention to primary actions and important data. 

It feels like a state-of-the-art consumer app (think modern ride-sharing or premium fitness apps), prioritizing usability on mobile devices.

### Key Characteristics:
*   **High Contrast & Premium Feel:** Deep blacks and dark greys contrasted with vibrant neon lime/green.
*   **Soft & Rounded:** Heavy use of rounded corners (pill shapes, large border radii) for all UI elements, cards, and buttons.
*   **Clean Typography:** Modern, highly legible geometric sans-serif typography (e.g., Inter, SF Pro, Circular).
*   **Spacious & Layered:** Ample padding, distinct dark-on-dark layering for cards, and subtle floating elements.

---

## 2. Color Palette

The color palette is streamlined to ensure the neon accent pops against the dark backgrounds.

| Role | Hex | Usage |
| :--- | :--- | :--- |
| **Deep Black (Base)** | `#000000` | Primary background, text on neon elements. |
| **Dark Grey (Surface)**| `#1A1A1A` to `#2A2A2A` | Cards, input fields, and secondary containers resting on the base background. |
| **Neon Lime (Primary)** | `#CCFF00` or `#CFFF04` | Main accent, primary buttons, active states, key icons, and highlights. |
| **Pure White** | `#FFFFFF` | Primary text, headings, and crucial icons. |
| **Muted Grey** | `#888888` | Secondary text, inactive states, placeholders. |

---

## 3. Typography

The typography should be extremely clean, modern, and friendly, moving away from harsh, raw system fonts.

### Font Families
1.  **Primary/UI:** `Outfit` (already bundled in `assets/fonts/` with weights 100–900).
    *   *Usage:* Used universally across the app for headings, body, and buttons.
    *   *Styling:* 
        *   Headlines: Large, bold (`600`-`700` weight), tight tracking.
        *   Body/Buttons: Medium/Semi-bold (`500`-`600`), highly legible.
        *   Captions/Labels: Use `Outfit` (not monospace) at lighter weights for consistency.

### Typographic Rules
*   **Hierarchy:** Clear distinction between large, impactful headings and smaller secondary text.
*   **Contrast:** Ensure all text has high contrast against its background. White on black/dark grey, or black on neon lime.
*   **No monospace:** Remove all `fontFamily: 'monospace'` overrides. Use `Outfit` everywhere.

---

## 4. UI Elements & Motifs

### A. Borders & Shapes
*   **Corners:** Exaggerated rounded corners. 
    *   Buttons are often full pill shapes (`borderRadius: 999`).
    *   Cards and containers use large radii (e.g., `16px`, `24px`, or `32px` depending on screen size).
*   **Borders:** Generally borderless. Separation is achieved through background color differences (dark grey on black) rather than explicit borders. Remove all thick `Border.all(width: 3)` or `width: 4` usages.

### B. Cards and Containers
*   Content is grouped into distinct, rounded dark grey cards resting on the pure black background.
*   Floating action buttons or summary cards often sit on top of map views with subtle, sophisticated drop shadows (not brutalist solid shadows) to provide depth.
*   Use `BoxShadow` with `blurRadius: 16` or more for soft elevation, never `Offset(4,4)` with zero blur.

### C. Buttons and Controls
*   **Primary Actions:** Large, pill-shaped buttons with the Neon Lime background and black text.
*   **Secondary Actions:** Dark grey pill buttons with white text, or outline buttons with neon text.
*   **Toggles/Selects:** Smooth, animated pill-shaped toggles.

### D. Map Styling (MapTiler + flutter_map)
*   Use **MapTiler** free-tier dark map style via `flutter_map`'s `TileLayer`.
*   URL template: `https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key={MAPTILER_API_KEY}`
*   The user needs to sign up at [maptiler.com/cloud](https://www.maptiler.com/cloud/) and get a free API key (add to `.env` as `MAPTILER_API_KEY`).
*   Roads and features should be muted, dark greys to keep the focus on the UI elements.
*   Markers and routes should use the signature Neon Lime color to stand out vividly.

---

## 5. Light Mode Implementation
While the primary identity is dark mode, if light mode is implemented, it must maintain the premium feel:
*   **Backgrounds:** Pure white or very light off-white.
*   **Surfaces/Cards:** Pure white with very subtle, soft drop shadows for elevation.
*   **Text:** Almost black (e.g., `#111111`).
*   **Primary Accent:** The Neon Lime must be adjusted slightly for contrast against white, or used strictly for solid buttons with black text.

---

## 6. Implementation Checklist (Mobile/App)

When building the Flutter mobile app UI:
- [ ] Ensure `fontFamily: 'Outfit'` is set in `ThemeData` (already configured).
- [ ] Remove `fontFamily: 'monospace'` from `AppTypography` captions and labels — use Outfit everywhere.
- [ ] Update all border radii tokens in `AppColors`: `radiusButton: 999`, `radiusCard: 24`, `radiusInput: 16`, `radiusDialog: 24`, `radiusChip: 999`.
- [ ] Remove all brutalist solid offset shadows (`BoxShadow` with zero blur and `Offset(4,4)`, `Offset(6,6)`, `Offset(8,8)` etc.) — replace with soft blurred shadows or remove entirely.
- [ ] Remove all thick borders (`Border.all(width: 3)`, `width: 4`) from widgets, nav bars, cards, and FABs.
- [ ] Update `AppColors.surfaceDark` from `#111111` to `#1A1A1A` for better card distinction.
- [ ] Update `AppColors.dividerDark` to a muted grey (e.g., `#2A2A2A`) instead of neon green.
- [ ] Update map `TileLayer` URLs to use MapTiler dark style: `https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key={MAPTILER_API_KEY}`.
- [ ] Add `MAPTILER_API_KEY` to `.env` file.
- [ ] Redesign `ReportMarker` to be a smooth glowing circle instead of a rotated square with thick borders.
- [ ] Redesign `CitizenMainScreen` bottom nav to use a sleek rounded container instead of thick-bordered bar.
- [ ] Redesign FAB to be a circular neon-lime button with no thick border, just a soft shadow.
- [ ] Ensure touch targets are large and surrounded by ample negative space.


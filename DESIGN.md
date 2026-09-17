# Ecopin Design System: Eco-Tech Subtle

This document outlines the core design language, aesthetic principles, and technical implementation details for the Ecopin app. This system takes inspiration from world-class mapping applications (like Google Maps), focusing on legibility, subtle visual hierarchy, and clean integration of data over complex map tiles.

## 1. Core Philosophy
The design bridges the gap between civic action and modern geospatial technology. Moving away from heavy, noisy brutalism, this style embraces a **Clean, Subtle, and Integrated** look. 

It communicates reliability, ease-of-use, and focus. The UI should float seamlessly above the map without competing for the user's attention.

### Key Characteristics:
*   **High Legibility:** Elements are clearly distinguishable from the map using soft shadows and subtle white/grey strokes.
*   **Approachable Geometry:** Generous border radiuses (pills, rounded rectangles, perfect circles) for a modern, friendly feel.
*   **Subtle Elevation:** Soft, diffused drop shadows to establish hierarchy (no hard/solid offsets).
*   **Balanced Visual Weight:** Avoid overly thick borders or massive icons that dominate the screen real estate.

---

## 2. Color Palette

The color system relies on neutral backgrounds with semantic accent colors used sparingly to direct attention.

| Role | Hex | Usage |
| :--- | :--- | :--- |
| **Surface (Light)** | `#FFFFFF` | Primary background for cards, navbars, and search bars in Light Mode. |
| **Surface (Dark)** | `#1E1E1E` | Primary background for UI elements in Dark Mode. |
| **Primary Accent** | `#0F9D58` | Main brand accent, primary buttons, user location indicator. |
| **Status: Resolved** | `#34A853` | Map markers for resolved/closed issues (Green). |
| **Status: Progress** | `#FBBC05` | Map markers for in-progress/acknowledged issues (Yellow). |
| **Status: Urgent** | `#EA4335` | Map markers for pending/urgent reports (Red). |
| **Divider / Stroke** | `#E0E0E0` | Subtle 1px borders to separate elements in Light Mode (`#333333` in Dark Mode). |

---

## 3. Typography

Typography should be clean, modern, and highly legible even at small sizes.

### Font Families
1.  **Primary/UI:** `Inter`, `Roboto`, or System Default Sans-Serif
    *   *Usage:* All standard UI elements (Search bars, navigation, card content).
    *   *Styling:* Use regular weights (`400`) for standard text, and medium/semibold (`500`/`600`) for headers and active states. Avoid overly heavy (`900`) weights.
2.  **Secondary/Data:** `monospace` (Only when strictly necessary)
    *   *Usage:* Specific technical data points like exact coordinates or IDs. Keep it minimal.

---

## 4. UI Elements & Motifs

### A. Borders & Shapes
*   **Thickness:** Use minimal, subtle borders (`1px`). Avoid thick outlines.
*   **Corners:** Highly rounded. Use `BorderRadius.circular(24)` or fully rounded "pill" shapes (`BorderRadius.circular(999)`) for search bars, floating buttons, and navbars.

### B. Interactions & Elevation (Soft Shadows)
*   **Containers (Nav, Search):** Use soft, widespread drop shadows to lift the UI off the map.
    *   *Example (Light):* `box-shadow: 0px 8px 24px rgba(0,0,0,0.12);`
    *   *Example (Dark):* `box-shadow: 0px 8px 24px rgba(0,0,0,0.40);`
*   **Floating Action Buttons:** Should appear slightly closer to the user with a tighter shadow.

### C. Map Markers (Pins)
*   **Size:** Keep them small and precise (e.g., 20x20 or 24x24). They should point to a specific location, not obscure an entire city block.
*   **Design:** Use simple, elegant circles or teardrops. 
*   **Map Separation:** Every pin **must** have a `2px` pure white (`#FFFFFF`) border. This stroke is critical for ensuring the pin remains visible regardless of the map tile colors behind it, especially in Light Mode.

### D. Map Controls (Right Side)
*   Must be secondary in visual hierarchy.
*   Use stacked, rounded squares (or circles) with a subtle shadow and solid white/dark-grey background.
*   Icons inside should be minimal and correctly scaled (e.g., 20px icons inside a 40px container).

---

## 5. Light vs Dark Mode Implementation

The design must feel native and cohesive in both modes.

### Light Mode
*   **Map Tiles:** Standard, detailed map tiles (like Google Maps or OSM). 
*   **UI Elements:** Pure white containers (`#FFFFFF`) with soft, transparent black shadows. 
*   **Text:** Dark grey/black for high readability.

### Dark Mode
*   **Map Tiles:** Dark, muted map tiles (e.g., CartoDB Dark Matter or customized dark styles).
*   **UI Elements:** Dark grey containers (`#1E1E1E` or `#2A2A2A`). 
*   **Shadows:** Shadows are less visible in dark mode; rely on subtle `1px` lighter grey borders (`#333333`) to separate floating containers from the dark map.
*   **Text:** Pure white or light grey.

---

## 6. Implementation Checklist for Mobile/App

- [ ] Revert thick `4px` borders to subtle `1px` borders or remove them entirely in favor of shadows.
- [ ] Implement `BorderRadius.circular(24)` or pill shapes for the Search Bar, Bottom Navbar, and Map Controls.
- [ ] Replace solid offset shadows with soft, modern drop shadows (e.g., `blurRadius: 16`, `offset: 0, 4`).
- [ ] Redesign pins and clusters to be small, circular, and feature a strict `2px` white stroke for map separation.
- [ ] Standardize visual weight: ensure icons and text are properly proportioned and not competing for attention.

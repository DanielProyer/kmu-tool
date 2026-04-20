# Design System: Industrial Precision
 
## 1. Overview & Creative North Star
 
### The Creative North Star: "The Digital Foreman"
This design system is not a generic SaaS template; it is a high-performance instrument. We are moving away from the "flat web" and toward **Industrial Brutalism**. Imagine a custom-milled Swiss watchcase or a perfectly organized tool wall in a high-end workshop. Every element must feel heavy, intentional, and engineered. 
 
We achieve a "High-End Editorial" look by combining the utilitarian grit of a workshop with the obsessive precision of Swiss typography. We break the standard grid through **functional asymmetry**: large, authoritative headlines paired with dense, data-heavy modules. We don't just "show" data; we "machine" it.
 
---
 
## 2. Colors & Surface Philosophy
 
The palette is rooted in the materials of the trade: **Deep Charcoal (`#2f3131`)**, **Industrial Grays**, and **Safety Orange (`#a04100`)**.
 
### The "No-Line" Rule
Standard UI relies on thin lines to separate ideas. We do not. To maintain a premium feel, **1px solid borders for sectioning are prohibited.** Boundaries are defined strictly through tonal shifts. A `surface-container-low` sidebar sitting against a `surface` background provides all the definition needed without the visual "noise" of a line.
 
### Surface Hierarchy & Nesting
Treat the interface as a physical assembly of plates. Use the `surface-container` tiers to create "milled" depth:
- **`surface-container-lowest` (#ffffff):** Used for the primary "work surface" or active paper-like documents.
- **`surface-container-low` (#f3f3f3):** The default background for the application shell.
- **`surface-container-high` (#e8e8e8):** Used for elevated UI elements like floating panels or active navigation states.
 
### The "Glass & Gradient" Rule
To elevate the "Tool Workshop" aesthetic into a premium space:
- **Signature Textures:** For primary CTAs, use a subtle vertical gradient from `primary` (#a04100) to `primary_container` (#ff6b00). This mimics the slight sheen of powder-coated metal.
- **Glassmorphism:** For overlays (modals/drawers), use a semi-transparent `inverse_surface` (#2f3131) at 85% opacity with a `20px` backdrop blur. This ensures the "workshop" remains visible behind the tool being used.
 
---
 
## 3. Typography: The Swiss Blueprint
 
Our typography reflects the clarity of technical drawings. We use **Public Sans** for high-impact structural elements and **Inter** for high-density data.
 
- **Display & Headline (Public Sans):** These are your "Engravings." They should be bold and authoritative. Use `display-lg` (3.5rem) for dashboard overviews to create a sense of scale.
- **Body & Title (Inter):** These are your "Technical Specs." Inter’s high x-height ensures readability even in complex inventory lists.
- **Editorial Contrast:** Always pair a `display-sm` headline with a `label-md` uppercase sub-header. This "Big-Small" relationship mimics high-end architectural journals.
 
---
 
## 4. Elevation & Depth: Tonal Layering
 
We do not use drop shadows to make things "pop." We use **Tonal Layering** to make things "fit."
 
### The Layering Principle
Depth is achieved by stacking. Place a `surface-container-lowest` card on a `surface-container-low` background. This creates a natural "lift" that feels like a sheet of metal resting on a workbench.
 
### Ambient Shadows
If an element must float (e.g., a floating action button), use **Ambient Shadows**:
- **Color:** A tinted version of `on-surface` (e.g., `#1a1c1c` at 6% opacity).
- **Blur:** Large and diffused (e.g., `24px` blur, `8px` Y-offset). It should look like soft light hitting an object, not a black glow.
 
### The "Ghost Border" Fallback
Where containment is required for high-density data (like a spreadsheet), use a **Ghost Border**. Use the `outline_variant` (#e2bfb0) at **15% opacity**. It should be felt rather than seen.
 
---
 
## 5. Components
 
### Buttons: The "Machine Switch"
- **Primary:** `primary` (#a04100) background, `on_primary` (#ffffff) text. Use the `sm` (0.125rem) roundedness scale for a sharp, machined edge. 
- **Secondary:** No background. Use a `Ghost Border` and `on_surface` text.
- **Interaction:** On hover, shift the background to `primary_container`. No "glow" effects.
 
### Input Fields: The "Stamped Label"
- **Style:** Use `surface_container_highest` (#e2e2e2) as the fill. 
- **Focus:** Transition the border to a 2px solid `primary` (#a04100). 
- **Typography:** Labels must be `label-md` in all-caps to mimic industrial stamping.
 
### Cards & Lists: The "Parts Bin"
- **Rules:** Forbid the use of divider lines.
- **Separation:** Separate list items using `8px` of vertical whitespace or by alternating background colors between `surface` and `surface_container_low`.
- **Layout:** Use intentional asymmetry. Place the "Action" (button/link) in the top right, and the "Data" (numbers/IDs) in a heavy, bold typeface in the center.
 
### Specialized Component: The "Status Gauge"
For craft companies, progress is everything. Instead of a standard progress bar, use a segmented "Gauge" using `primary` for active segments and `surface_variant` for inactive ones, mimicking an analog mechanical display.
 
---
 
## 6. Do's and Don'ts
 
### Do:
- **Embrace White Space:** Treat space as a luxury material. It provides the "cleanliness" in the workshop.
- **Use High-Contrast Labels:** Use `on_surface_variant` for secondary info but keep it legible.
- **Align to the Grid, but Break the Symmetry:** Keep data blocks aligned, but let hero images or large numbers bleed across columns.
 
### Don't:
- **Don't use "Soft" Shadows:** No rounded, bubbly shadows. If it’s not an ambient light shadow, don’t use it.
- **Don't use Rounded Corners for everything:** Stick to `sm` (0.125rem) or `none` for a sturdy, industrial feel. Avoid `xl` or `full` unless it's a specific status chip.
- **Don't use Dividers:** If you feel the need for a line, try using a 16px gap or a color shift first. Precision is found in the gaps, not the borders.
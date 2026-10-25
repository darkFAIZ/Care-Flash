---
name: Care-Flash and Care-Merchant
description: A shared, calm care-record system for seeker and caregiver apps.
colors:
  primary: "#174D45"
  ink: "#20332E"
  paper: "#F6F2E8"
  paper-raised: "#FFFDF7"
  paper-soft: "#FBF8F1"
  input-fill: "#EAE4D7"
  record-rule: "#D8D2C5"
  stamp-gold: "#E7B24C"
  stamp-terracotta: "#D7735B"
  success: "#12B76A"
  success-container: "#D1FADF"
  warning: "#F59E0B"
  warning-container: "#FEF0C7"
  danger: "#D92D20"
  danger-container: "#FEE4E2"
typography:
  display:
    fontFamily: "PlusJakartaSans, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.4px"
  headline:
    fontFamily: "PlusJakartaSans, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    letterSpacing: "-0.2px"
  title:
    fontFamily: "PlusJakartaSans, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.2px"
  body:
    fontFamily: "PlusJakartaSans, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "PlusJakartaSans, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.35
rounded:
  sm: "12px"
  md: "16px"
  lg: "24px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  page-gutter: "20px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    rounded: "{rounded.md}"
    height: "52px"
    typography: "{typography.title}"
  button-secondary:
    rounded: "{rounded.md}"
    height: "52px"
    typography: "{typography.title}"
  button-ghost:
    rounded: "{rounded.md}"
    height: "48px"
    typography: "{typography.title}"
  card:
    backgroundColor: "{colors.paper-soft}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
  field:
    backgroundColor: "{colors.input-fill}"
    rounded: "{rounded.sm}"
    padding: "15px 16px"
  status-chip:
    rounded: "999px"
    padding: "6px 10px"
    typography: "{typography.label}"
  navigation:
    backgroundColor: "{colors.paper}"
    height: "72px"
---

# Design System: Care-Flash and Care-Merchant

## Overview

**Creative North Star: "The Clinic Visit Record"**

The shared visual language treats a care request as a legible visit record: warm paper-like surfaces, deep green text and actions, restrained status color, and compactly organized details. It is calm and practical rather than a generic dashboard; the record card brings status, visit facts, and the next action into one readable unit.

Both apps use the same Material 3 theme foundation, Plus Jakarta Sans, spacing, shapes, and shared UI widgets. The home surfaces differ by role—Care-Flash foregrounds starting or following a request; Care-Merchant foregrounds caregiver readiness and the request or active visit—while retaining the same record-first card grammar.

**Key Characteristics:**
- Warm, lightly ruled surfaces with deep green as the shared brand seed.
- Distinct status tints and restrained gold/terracotta accents.
- Reused typography, component shapes, and page width across both apps.

## Colors

The palette pairs a puskesmas-green action color with warm paper neutrals; Material 3 derives additional scheme roles from the same seed, with explicit semantic colors for status.

### Primary
- **Puskesmas Green** (`primary`): Shared seed and action color in both apps; it also marks visit-detail icons, highlighted cards, and next-step links.

### Secondary
- **Record Gold** (`stamp-gold`): The shared theme's secondary accent; use sparingly for warm status or emphasis rather than as a competing action color.

### Tertiary
- **Terracotta Stamp** (`stamp-terracotta`): The shared theme's tertiary accent for occasional emphasis.

### Neutral
- **Warm Record Ink** (`ink`): Primary light-theme text.
- **Clinic Paper** (`paper`): Light-theme scaffold and app-bar surface.
- **Raised Paper** (`paper-raised`) and **Soft Paper** (`paper-soft`): Light-theme surface layers used for low/raised containers and shared card backgrounds.
- **Ruled Divider** (`record-rule`): Light-theme outline variant and record divider.
- **Success Green**, **Caution Amber**, and **Alert Red** (`success`, `warning`, `danger`) with their matching container tokens: semantic status colors for confirmations and status chips. Dark mode supplies separate semantic variants.

### Named Rules
**The Shared Seed Rule.** Care-Flash and Care-Merchant use the same green seed by default; optional appearance accents replace the seed and regenerate the Material 3 scheme.

## Typography

**Display Font:** Plus Jakarta Sans (sans-serif fallback)  
**Body Font:** Plus Jakarta Sans (sans-serif fallback)  
**Label/Mono Font:** No separate label or mono family is configured.

**Character:** Rounded, contemporary letterforms keep the interface approachable; close-set bold headings provide hierarchy while regular body text stays readable. The font is registered through bundled Google Fonts assets.

### Hierarchy
- **Display** (700, 28px, 1.15 line height, -0.4px tracking): Feature or large-screen title style.
- **Headline** (700, 24px): Home greeting and high-level screen heading.
- **Title** (600, 20px, 1.25 line height, -0.2px tracking): Section headers and record identity; a 16px semibold title-small supports compact actions.
- **Body** (400, 15px, 1.45 line height): Main reading text and visit information.
- **Label** (500, 13px, 1.35 line height): Supporting fields and compact labels; status labels are strengthened to semibold.

### Named Rules
**The Shared Type Rule.** Use the Plus Jakarta Sans Material scale across both apps; distinguish record metadata through size, weight, and semantic color, not a second typeface.

## Layout

Both home surfaces center a vertically scrolling list inside a maximum 680px content width. The page rhythm uses a 20px horizontal gutter and 16px vertical page padding, with a shared 4/8/12/16/24/32px spacing scale. Related rows use tighter gaps; section breaks and card content use larger steps. Detail rows wrap when needed rather than relying on a fixed multi-column grid. The implemented layout is adaptive, but no named breakpoint scale is defined.

The Care-Flash home pairs a welcome and start-request card with an ongoing visit record and quick actions. The Care-Merchant home keeps the caregiver status header above one relevant onboarding, incoming-request, waiting, or active-booking card. These role-specific compositions are not universal templates for other screens.

## Elevation & Depth

The shared card treatment is flat: zero elevation, transparent surface tint, and a thin outline variant. In light mode, tonal paper layers and ruled dividers provide separation; Material 3 supplies the dark color scheme rather than hard-coded dark paper values. Dialogs and sheets are also configured without surface tint. No custom shadow vocabulary is defined.

### Named Rules
**The Ruled-Surface Rule.** Separate shared cards with tone and a subtle border, not a drop shadow.

## Shapes

The form language uses gently rounded rectangles: fields and small tiles are 12px, cards and buttons 16px, and sheets/dialogs 24px. Cards clip their contents to the card shape; status chips are fully pill-shaped. Borders are fine and tonal, with a stronger primary outline for highlighted shared cards.

## Components

### Buttons
- **Character:** Direct, high-visibility actions with a shared minimum touch height.
- **Shape:** Gently rounded (16px).
- **Primary:** Material filled-button treatment using the scheme's primary/on-primary colors; minimum size is 64×52px and the shared `AppButton` expands to full width by default.
- **Secondary:** Outlined with the scheme outline and primary foreground; same 64×52px minimum.
- **Ghost:** Text treatment with a 48×48px minimum.
- **Danger:** Filled semantic danger action with white foreground, reserved in the shared widget for the Report action.
- **State:** Loading retains the selected variant's enabled colors and shows a compact spinner. Material handles interaction states; no custom hover transition is defined.

### Chips
- **Style:** Compact status pills (10px horizontal, 6px vertical padding) with 999px corners, optional 15px icon, and semibold 13px label.
- **State:** Neutral and informational chips use scheme surfaces; success, warning, and danger use semantic foreground/container pairs, with separate light and dark values.

### Cards / Containers
- **Character:** Flat, lightly outlined containers keep actionable and informational records legible.
- **Corner Style:** 16px.
- **Background:** Shared `AppCard` uses the theme's low surface container; home cards may use role-appropriate scheme containers.
- **Shadow Strategy:** No elevation; use tonal layering and outline.
- **Border:** One-pixel outline variant; highlighted `AppCard` uses a 1.5px primary border.
- **Internal Padding:** 16px by default; compact cards use 16px horizontal and 12px vertical padding.

### Inputs / Fields
- **Style:** Filled with the scheme's highest surface container, 12px corners, and 16px horizontal/15px vertical content padding. Shared fields support labels above the control or a floating label inside it.
- **Focus:** Primary-colored 2px border; default and enabled borders use the outline variant.
- **Error / Disabled:** Error borders use the scheme error color, with a 2px focused error border. Disabled appearance follows Material defaults.

### Navigation
- **Style:** Material 3 navigation bar, 72px high, flat on the scheme surface, with a primary-container selection indicator and always-visible small labels. Navigation icons are 24px.
- **Behavior:** Both apps use the shared theme; the exact destination set is app-specific.

### Clinic Visit Record
The home visit record groups a status chip and forward affordance, care type or caregiver identity, ruled visit metadata, reference, and one next-step link/action in a single tappable card. Care-Flash shows caregiver/help type, location, date and time, and request reference. Care-Merchant shows request/visit status, reference, care type, location or scheduling/price metadata, and the appropriate response or progression action. Keep these as true booking facts rather than decorative labels.

## Do's and Don'ts

### Do:
- **Do** use the shared green-seeded Material 3 theme and shared typography, spacing, and radius scales by default.
- **Do** keep status meaning explicit through semantic colors and labels, and maintain readable contrast between each container and foreground.
- **Do** organize a visit record so its current state and actionable next step are easy to find.
- **Do** preserve the 680px home content maximum and 20px page gutter where using the established home layout.

### Don't:
- **Don't** add drop shadows to the shared flat card treatment.
- **Don't** use status colors as interchangeable decoration; success, warning, and danger are separate semantic states.
- **Don't** promote one app's home composition into a mandatory layout for every screen; the shared system supports role-specific workflows.

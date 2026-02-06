---
name: UI/UX Design
description: "Use when creating design specs, building design systems, applying UX principles, or reviewing UI implementations for design fidelity. Provides design spec templates, component documentation patterns, and accessibility guidelines."
version: 1.0.0
---

# UI/UX Design Skill

## Design Spec Template

```markdown
# Component: [Name]

## Purpose
[Why this component exists]

## Variants
- Default
- [Variant 2]
- [Variant 3]

## Props/Configuration
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| | | | |

## States
- **Default**: [description + visual notes]
- **Hover**: [description + visual notes]
- **Active/Pressed**: [description + visual notes]
- **Focus**: [description + visual notes]
- **Disabled**: [description + visual notes]
- **Loading**: [description + visual notes]
- **Error**: [description + visual notes]
- **Empty**: [description + visual notes]

## Layout
- Width: [fixed/fluid/min-max]
- Height: [fixed/fluid/min-max]
- Padding: [values]
- Margin: [context-dependent notes]

## Typography
- Font: [family, size, weight, line-height]
- Color: [token or value]
- Truncation: [behavior for overflow text]

## Responsive Behavior
- Mobile (<768px): [changes]
- Tablet (768-1024px): [changes]
- Desktop (>1024px): [default]

## Accessibility
- Role: [ARIA role]
- Keyboard: [interaction pattern]
- Screen reader: [announcement behavior]
- Focus order: [tab sequence]

## Animation
- Transition: [property, duration, easing]
- Enter: [animation]
- Exit: [animation]
- Reduced motion: [alternative]
```

## Design System Scan Procedure

When scanning an existing codebase for design patterns:

1. **Find style sources**: Look for CSS variables, theme files, design tokens
   - Glob: `**/*.{css,scss,less}` for `--` or `$` prefixed variables
   - Glob: `**/theme.{ts,js,json}` or `**/tokens.*`

2. **Find component library**: Look for shared components
   - Glob: `**/components/**/*.{tsx,jsx,vue,svelte}`
   - Note: reusable vs. page-specific components

3. **Extract color palette**: Document all colors with usage context
4. **Extract typography scale**: Font sizes, weights, line heights
5. **Extract spacing scale**: Padding/margin patterns
6. **Document component inventory**: List all shared components

## Accessibility Quick Reference

### WCAG 2.1 AA Requirements
| Requirement | Standard | How to Check |
|------------|----------|-------------|
| Color contrast (text) | 4.5:1 ratio | Use contrast checker tool |
| Color contrast (large text) | 3:1 ratio | Text >= 18pt or 14pt bold |
| Focus visible | Clear indicator | Tab through interface |
| Keyboard operable | All actions via keyboard | No mouse-only interactions |
| Alt text | All images | Decorative = empty alt |
| Form labels | All inputs labeled | Associated via for/id or aria |
| Error identification | Clear error messages | Not color-only |
| Resize text | 200% without loss | Browser zoom test |

### Common ARIA Patterns
```html
<!-- Button with loading state -->
<button aria-busy="true" aria-label="Saving...">

<!-- Expandable section -->
<button aria-expanded="false" aria-controls="panel-1">
<div id="panel-1" role="region" hidden>

<!-- Live region for updates -->
<div aria-live="polite" aria-atomic="true">

<!-- Dialog -->
<div role="dialog" aria-modal="true" aria-labelledby="title">
```

## Color Usage Guidelines

| Purpose | Token Name | Usage |
|---------|-----------|-------|
| Primary action | `--color-primary` | CTAs, links, focus rings |
| Destructive | `--color-danger` | Delete, error states |
| Success | `--color-success` | Confirmations, valid states |
| Warning | `--color-warning` | Caution states |
| Neutral | `--color-neutral` | Borders, dividers, subtle text |
| Background | `--color-bg` | Page and card backgrounds |
| Surface | `--color-surface` | Elevated elements |

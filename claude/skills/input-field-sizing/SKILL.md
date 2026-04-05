---
name: input-field-sizing
description: Use when sizing an HTML input field to fit N characters wide in a proportional font, or when preventing text overflow without a hard character limit. Symptoms: field too wide with ch units, field not scaling when font size changes, field resolving unexpectedly narrow with percentage-based width, hard maxLength feeling wrong because spaces are narrower than letters.
---

# Input Field Sizing and Overflow Prevention

## Overview

Two related problems, two distinct solutions:

1. **Sizing a field to fit exactly N characters** — use `em` units.
2. **Preventing text from going off-screen without a hard character limit** — use a `scrollWidth` overflow check in `onChange`.

---

## Part 1 — Sizing a Field to N Characters

Use `em` units — not `ch`, `rem`, or percentage. `em` scales with the element's inherited font size, keeping character capacity constant across font size changes.

### Why Other Approaches Fail

| Approach | Symptom | Root Cause |
|----------|---------|------------|
| `Nch` | Field ~17% too wide | `ch` = width of "0", which is wider than the average letter |
| `size={N}` + `width: auto` | Same result as `ch` | Browsers compute `size` using similar metrics to `ch` |
| CSS grid + hidden sizing span | Breaks baseline alignment | `inline-grid` aligns to baseline differently than `inline-block` in flex rows |
| `w-[min(Xrem, 100%)]` | Field resolves to `min-width` (~30 chars instead of 40) | Circular reference: parent sizes to child, child uses `%` of parent — browser falls back to `min-width` |
| Fixed `rem` | Correct at one font size, wrong at all others | `rem` = root font size (browser default ~16px), never changes |

### The Circular Percentage Trap

`w-[min(Xrem, 100%)]` inside a flex or inline-block container that itself sizes to content creates a circular reference:

```
Parent width  = max-content of children
Child width   = min(Xrem, 100% of parent)   ← depends on parent
```

Browsers resolve this by substituting `min-width` for the `%` term. If `min-width: 200px`, the field becomes 200px (~30 chars) instead of the intended 18rem (~40 chars).

**Fix:** Use a fixed unit with no percentage — `w-[18em]`, not `w-[min(18rem,100%)]`.

### The CSS min-width Trap

If the component's CSS class sets a `min-width` (e.g. `.underline-field { min-width: 200px }`), a Tailwind `w-[8em]` will silently have no effect when `8em < 200px`. The workaround `!min-w-0` works but is tedious. The real fix: **don't put `min-width` in a CSS class**. If a default min-width is needed, apply it as a Tailwind class in the component's own JSX so it's in the same specificity tier and can be straightforwardly overridden by caller-provided classes (with tailwind-merge) or just removed when an explicit width is passed.

### The Solution

```jsx
className="w-[18em]"
```

`em` is relative to the element's own inherited font size. When an ancestor sets `font-size: 12pt`, all `em` units inside resolve against that. Changing to `14pt` widens the field proportionally — character capacity stays constant.

### Calibrating the em Value

For proportional fonts, `em`-based sizing is an approximation. A practical starting point:

- Times New Roman, mixed-case Latin: **0.5 em per character**
- Formula: `N × 0.5em`
- 18 characters ("September 28, 2028") → `18 × 0.5 = 9em` ✓

Verify empirically: the field is correctly sized when a user typing a realistic value never triggers the overflow guard before filling the visible area.

### rem vs em

| Unit | Relative To | Use When |
|------|-------------|----------|
| `rem` | Root `html` font size (fixed ~16px) | UI chrome, spacing outside the document |
| `em` | Current element's inherited font size | Content inside a document with a configurable font size |

For any field inside a document where an ancestor sets font size dynamically (e.g. `style={{ fontSize: '${pt}pt' }}`), always use `em` for widths that should scale with the font.

---

## Part 2 — Preventing Overflow Without a Hard Character Limit

`maxLength` is a blunt instrument — it counts characters, but spaces and narrow letters (i, l, 1) consume far less width than wide ones (W, M, m). The result: the field cuts off early for wide text, or allows too much for narrow text.

**Better approach:** reject the keystroke only when the text would visually overflow the input.

### How It Works

When `onChange` fires on a controlled React input, the browser has already rendered the new value into the DOM. At that moment, `e.target.scrollWidth > e.target.clientWidth` is true if the content overflows — before React reverts it. Returning without calling the state setter causes React to restore the previous value.

```tsx
onChange={(e) => {
  if (e.target.scrollWidth > e.target.clientWidth) return;
  onChange(e.target.value);
}}
```

This works correctly for:
- Typing (single character added)
- Paste (entire string rejected if it overflows)
- Deletion (always allowed — scroll width shrinks)

### Requirements

The input must have `overflow: hidden` and `white-space: nowrap` for `scrollWidth` to accurately reflect overflow. Without these, `scrollWidth === clientWidth` even when text is clipped.

```css
.underline-field input {
  overflow: hidden;
  white-space: nowrap;
}
```

### When to Use Each

| Approach | Use When |
|----------|----------|
| `scrollWidth` overflow check | The limit is visual — "don't go off the line" |
| `maxLength` on a native `<input>` | The limit is semantic, not visual (e.g. a fixed-format code where character count is meaningful regardless of width) |
| Both together | Never — they solve the same problem differently; pick one |

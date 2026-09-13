# Accessibility checklist (issue #6)

Tail Tally must stay usable with TalkBack/VoiceOver, large system text, high
contrast, and rotation. This checklist is the manual gate for each release;
the automated half lives in `test/app/accessibility_test.dart`.

## Automated regression tests (`flutter test test/app/accessibility_test.dart`)

- [x] Every timeline card shows a word-based status chip ("Overdue" /
      "Due now" / "Coming up" / "Done") announced as `Status: <word>`.
- [x] Completing a task swaps the chip to "Done" (words, not just the green
      check icon).
- [x] Done buttons announce "Mark <routine> for <pet> done", never a bare
      "Done" out of context.
- [x] Pet filter chips announce "Filter to <pet>, <species>" / "Show all
      pets".
- [x] Timeline renders at 1.5x text scale and in landscape without overflow.
- [x] Reminder settings stays usable at 1.5x text scale.
- [x] Privacy status messages are live regions (announced on change).

## Manual device pass (do once per release on one Android + one iOS device)

### TalkBack / VoiceOver sweep
- [ ] Timeline: one swipe per card announces pet, routine, time window, and
      status; the Done button announces the full task name.
- [ ] Focus order follows visual order: filter chips → group header → cards
      (overdue first), no phantom stops.
- [ ] Completion: snackbar announces "<routine> marked done" and the Undo
      action is focusable.
- [ ] Note dialog: focus moves into the dialog, traps inside it, and returns
      to the card after dismiss.
- [ ] Reminders screen: switch announces on/off state; permission-denied
      fallback card is read as one block; status line is announced after
      each change.
- [ ] Privacy screen: export/import/retention outcomes are announced; the
      delete-all confirmation dialog is fully readable and its destructive
      button is clearly labelled.

### Dynamic text
- [ ] Set system font scale to largest (Android "Font size" max / iOS
      Larger Text AXSize). No clipped or overlapping text on timeline,
      reminders, or privacy screens; nothing scrolls off irrecoverably.

### Contrast / color
- [ ] With status colors in mind: overdue/due/completed states remain
      distinguishable in grayscale screenshots (the status chip words carry
      the meaning; color is decoration only).
- [ ] iOS "Increase Contrast" and Android high-contrast text: chips and
      buttons stay legible.

### Orientation
- [ ] Rotate to landscape on timeline, reminder settings, and privacy
      screens: content reflows, nothing overflows.

### Touch targets
- [ ] Status chips are non-interactive labels; every interactive element
      (chips, buttons, toggles, list rows) has a target ≥ 48dp.

## UI contract (what the tests lock in)

- Key `group-header-<group>` marks a timeline section header.
- Key `status-<windowId>-<startMillis>` is on each card's status chip.
- Keys `complete-…`, `handoff-…`, `note-save`, `reminders-enabled`,
  `lead-time`, `quiet-hours-off`, `permission-fallback`,
  `request-permission`, `reminder-status`, `privacy-status`,
  `retention-preference`, `export-csv`, `import-backup`,
  `delete-all-data`, `delete-all-confirm`, `import-confirm`,
  `open-privacy-settings`, `open-reminder-settings` remain the
  screen-reader/widget-test contract.

# 6.5-inch iPhone screenshots

Four genuine Simulator captures of the native SwiftUI app, using fictional household data:

1. `6.5-inch/01-today.png` — daily care timeline
2. `6.5-inch/02-household.png` — pets and household members
3. `6.5-inch/03-history.png` — notes and completed care
4. `6.5-inch/04-settings.png` — reminders and local data controls

All images are portrait PNGs, **1242 × 2688**, captured on an iPhone 11 Pro Max simulator running iOS 26.5. This is an accepted 6.5-inch App Store screenshot size: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications

To regenerate, boot a dedicated iPhone 11 Pro Max simulator and run:

```sh
scripts/capture-screenshots.sh <simulator-UDID>
```

The script builds Debug, uses a separate screenshot store and DEBUG-only sample fixtures, and captures each tab. The Release app starts empty and has no sample-data launch options. The final icon is the green paw/checkmark/tail artwork supplied by the user; the earlier purple icon is not used.

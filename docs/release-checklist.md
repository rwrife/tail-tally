# iPhone release checklist

- Run `swift test` and the native simulator build in CI.
- Run the app on an iPhone and test setup, complete/undo, history notes, and relaunch persistence.
- Verify notification permission granted/denied, quiet hours, completion cancellation, and timezone changes.
- Export/import JSON and a legacy Flutter v1 backup; verify invalid imports leave current data untouched.
- Export CSV for a chosen date range; confirm retention and delete-all flows.
- Confirm `UIDeviceFamily` is `[1]` in the built app; Catalyst, Mac-designed, and Vision-designed support are disabled.
- Check the final supplied green icon on the Home Screen; the asset is an opaque 1024×1024 PNG.
- Review `app-store/description.md` and upload the 1242×2688 PNGs in `app-store/screenshots/6.5-inch/`.
- Supply your support URL and privacy-policy URL in App Store Connect. Review privacy declarations against the final binary.
- Select the developer team and archive the Release configuration for distribution. CI artifacts are unsigned simulator builds, not App Store submissions.
- Complete the accessibility checks in `docs/accessibility.md` before submission.

No App Store upload or submission is performed by this repository’s CI.

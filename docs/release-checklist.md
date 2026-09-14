# Release and internal distribution checklist

The source version is `pubspec.yaml` (`<semver>+<positive build number>`). A
release tag omits the build suffix and must exactly equal `v<semver>`; for this
candidate, `0.1.0-rc.1+2` maps to `v0.1.0-rc.1`. The tested
`tools/release.py validate` guard rejects a mismatch before either build starts.

## Automated gates

These gates run in the `quality` job. Android and iOS packaging depend on that
job, and the tag-only GitHub prerelease depends on both packaging jobs.

- [ ] Locked dependencies resolve without changing tracked files.
- [ ] `dart format --output=none --set-exit-if-changed .` passes.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` passes.
- [ ] Release helper unit tests pass, including mismatched-tag rejection.
- [ ] The full Flutter test suite passes with coverage.
- [ ] Drift repository and schema migration tests pass explicitly.
- [ ] Privacy, backup/import, CSV export, and retention tests pass explicitly.
- [ ] Accessibility regression tests pass explicitly.

## Candidate preparation

- [x] Set `pubspec.yaml` to `0.1.0-rc.1+2` (increased from `0.1.0+1`).
- [x] Add the `0.1.0-rc.1+2` entry to `CHANGELOG.md`.
- [ ] Review the changelog against the candidate commit.
- [ ] Run the workflow manually with expected version `0.1.0-rc.1+2` and
  install/exercise the downloaded internal artifacts.
- [ ] Create and push annotated tag `v0.1.0-rc.1` only after review. A matching
  pushed tag reruns every gate, then creates a GitHub prerelease.

## Artifact and signing truth

- Android output is `tail-tally-<version>-android-debug-signed.apk`. Flutter's
  debug build uses a CI-generated debug key. Replacing that key changes signing
  identity, so an existing installation may need to be uninstalled (losing its
  app-local data unless exported first). A controlled release keystore and
  secure signing workflow are required before store/device distribution claims.
- iOS output is `tail-tally-<version>-ios-simulator-unsigned-app.tar.gz`. It is
  an unsigned Simulator `.app`, not an IPA, not installable on physical iOS
  devices, and not suitable for App Store/TestFlight submission. Certificates,
  provisioning, archive/export, and device testing remain follow-up work.
- Workflow artifacts are retained for 14 days in
  [GitHub Actions](https://github.com/rwrife/tail-tally/actions). Artifact names
  include the workflow attempt, and publication downloads only the current
  attempt. Every required artifact must therefore come from the same full-run
  attempt; the workflow fails closed instead of mixing artifacts across build
  attempts. A tag run also attaches both binaries, `SHA256SUMS`, and
  `PROVENANCE.json` to [GitHub Releases](https://github.com/rwrife/tail-tally/releases).
- Published release tags and their assets are immutable. Never rerun, upload
  over, or edit a published release. Bump the prerelease and mobile build number,
  then create a new candidate with a new rc tag/build.

For an unpublished failed run, use **Re-run all jobs** in GitHub Actions or
`gh run rerun RUN_ID`. Do not use `gh run rerun --failed` or `gh run rerun --job`:
partial reruns are unsupported because publication requires all artifacts from
the same `run_attempt` and fails closed rather than mixing build attempts.

## Concrete manual artifact check

From a clean checkout on the candidate branch, trigger and download the exact
successful attempt (replace `<candidate-branch>` with its branch name):

```bash
gh workflow run ci.yml --ref <candidate-branch> -f expected_version=0.1.0-rc.1+2
run_id="$(gh run list --workflow ci.yml --branch <candidate-branch> --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$run_id" --exit-status
attempt="$(gh api "repos/rwrife/tail-tally/actions/runs/$run_id" --jq .run_attempt)"
gh run download "$run_id" --pattern "tail-tally-0.1.0-rc.1+2-*-attempt-$attempt" --dir dist
```

Install the APK on an authorized Android test device or emulator, and the
unsigned app on an already-booted iOS Simulator:

```bash
adb install -r dist/tail-tally-0.1.0-rc.1+2-android-debug-signed-attempt-*/tail-tally-0.1.0-rc.1+2-android-debug-signed.apk
tar -xzf dist/tail-tally-0.1.0-rc.1+2-ios-simulator-unsigned-app-attempt-*/tail-tally-0.1.0-rc.1+2-ios-simulator-unsigned-app.tar.gz -C dist
xcrun simctl install booted dist/Runner.app
xcrun simctl launch booted com.rwrife.tailTally
```

After a new tag passes every automated gate, its prerelease is automatically
available on GitHub Releases. That availability is not approval for wider
distribution: wider distribution remains manually gated until every applicable
physical-device, signing, and release-readiness item below is actually checked.

## Manual verification (not yet verified for this candidate)

- [ ] Accessibility smoke test with TalkBack and VoiceOver on supported devices;
  verify focus order, labels, text scaling, contrast, and reduced-motion behavior.
- [ ] Privacy smoke test: deny notifications, inspect requested permissions,
  export/import a backup, export CSV, exercise retention, and confirm delete-all.
- [ ] Upgrade/data-preservation test from the preceding installed candidate.
- [ ] Confirm no account, cloud service, telemetry, location, camera, or
  microphone requirement has been introduced.
- [ ] Confirm wording remains a routine organizer and makes no veterinary,
  diagnostic, treatment, or emergency-monitoring claim.

## Source reproduction

Use the commit and Flutter version recorded in `PROVENANCE.json`, check out the
commit detached, run `flutter pub get --enforce-lockfile`, then run the recorded
build commands on the corresponding GitHub-hosted runner OS. Verify downloads
with `sha256sum -c SHA256SUMS` from the asset directory. This provides useful
source traceability and reproduction instructions; it does **not** promise
byte-identical archives because hosted runner images, platform toolchains,
generated debug keys, and archive metadata can vary.

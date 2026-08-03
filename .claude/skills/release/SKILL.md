---
name: release
description: Cut an iOS TestFlight release — version bump, release IPA build, git tag, push, and upload to App Store Connect via mobile/scripts/release-ios.sh. Use when the user says "release", "cut a release", "testflight", "make a testflight build", "ship a build to testers", or "push a new version".
---

Run the iOS release: bump the version, build the alpha-flavour release IPA,
commit + tag + push, and upload to TestFlight.

`mobile/scripts/release-ios.sh` does all of it. This skill is about running it
from the right place, with the right flag, and knowing what its failures mean —
the script has no rollback, and it pushes a tag before it uploads.

## What the script does

In order: rewrite `version:` in `mobile/pubspec.yaml` → `flutter build ipa
--flavor alpha --dart-define-from-file=dart_define/alpha.json --release` →
`git commit mobile/pubspec.yaml -m "Release vX.Y.Z"` → `git tag vX.Y.Z` →
`git push origin HEAD` + push tag → `xcodebuild -exportArchive` with
`-allowProvisioningUpdates`.

Flags: `--patch` (else minor), `--dry-run`, `--skip-upload`, `--yes`.

## Step 1 — Preconditions

All four must hold. Check them before touching the script.

1. **Run from the main worktree.** The script commits and pushes from
   `mobile/..`, so running it inside `.claude/worktrees/<name>` would commit the
   version bump to the feature branch instead of `master`. Always:
   `cd /Users/gannon/Development/CribbageClub`.

2. **On `master`, clean, and in sync.** `git status -sb` shows
   `## master...origin/master` with no divergence and nothing modified. The
   script aborts on a dirty `mobile/` tree anyway, but a *diverged* master will
   push more than the user expects.

3. **The work being released is actually on master.** If the user just asked to
   ship a branch, `/ship` it first. Releasing from a master that doesn't contain
   the change produces a TestFlight build without it — silently.

4. **The mobile app builds and analyzes clean:**
   ```bash
   cd mobile && flutter analyze lib
   ```
   Scope to `lib` — bare `flutter analyze` reports ~90 pre-existing errors from
   vendored `rust_builder/cargokit/`. A release build failing 6 minutes in on
   something `analyze` would have caught in 5 seconds is a bad trade.

## Step 2 — Pick the bump, confirm with a dry run

**`--patch` is this project's convention** — v1.0.1 through v1.0.11 are all
patch bumps. Use it unless the user asks otherwise or the release carries
something big enough that the version should say so (a redesign, a new mode);
in that case say you're proposing a minor bump and why, rather than silently
choosing. The script's own default is minor, so `--patch` must be explicit.

Always dry-run first — it prints the exact version transition, and it's free:

```bash
./mobile/scripts/release-ios.sh --patch --dry-run
```

Show the user the `Current → New → Tag` lines. Cross-check `git tag
--sort=-v:refname | head -3` — if the computed tag already exists, the pubspec
and the tags have drifted and you must stop and sort that out first.

## Step 3 — Run it

The IPA build takes several minutes, so run it in the background and watch the
output rather than blocking:

```bash
cd /Users/gannon/Development/CribbageClub && ./mobile/scripts/release-ios.sh --patch --yes
```

with `run_in_background: true`, then arm a Monitor on the task's output file
whose filter covers **failure as well as progress** — a monitor that only greps
for success stays silent through a signing failure and silence reads exactly
like "still building":

```
tail -f <task-output-file> | grep -E --line-buffered \
  "Building IPA|Archive built|Committing|Pushing|Uploading|Upload complete|Released|Error|error:|FAILED|failed|Exception|No profiles|requires a provisioning|Aborted|xcodebuild: error"
```

`--yes` skips the script's interactive confirm, which can't be answered from a
background shell. Only pass it once the user has approved the release — the dry
run in Step 2 is where they approve it.

## Step 4 — Verify

Don't take exit 0 as proof. Confirm all four:

```bash
grep '^version:' mobile/pubspec.yaml            # → the new version
git log --oneline -1                            # → Release vX.Y.Z
git ls-remote --tags origin vX.Y.Z              # → the tag is on origin
git status -sb | head -1                        # → in sync, no divergence
```

and that the output ends with `** EXPORT SUCCEEDED **` / `Upload succeeded.`.

Tell the user App Store Connect still has to process the package before it
reaches testers, and summarize what's in the build.

## Failure modes

**Signing.** The export uses `-allowProvisioningUpdates`, so Xcode may try to
renew a certificate or profile and ask for the Apple ID. **Do not enter
credentials** — report exactly what it's asking for and let the user handle it.
`No profiles for 'com.jackabee.cribbageClub' were found` means the provisioning
profile needs regenerating in Xcode or on the developer portal.

**Duplicate build number.** The script bumps the version string but does **not**
touch the `+build` suffix in `pubspec.yaml`. App Store Connect rejects a build
whose build number already exists for that version, so a second upload at the
same version will fail here. Fix by incrementing the `+N` in `pubspec.yaml`, and
suggest teaching the script to do it.

**Dirty tree.** `Error: Working tree has uncommitted changes in mobile/.` —
commit or stash first (`/ship`), then re-run.

**Failure after the tag is pushed.** Everything through the tag push is done
before the upload starts, so an upload failure leaves the version bumped,
committed, tagged and pushed. Do **not** re-run the script — it would bump
again. Fix the upload cause and re-export the existing archive:

```bash
xcodebuild -exportArchive \
  -archivePath mobile/build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist mobile/scripts/ExportOptions.plist \
  -allowProvisioningUpdates
```

**Staging backend.** The build points at the public staging server
(`mobile/dart_define/alpha.json` → `https://cribbage-staging.tail0b042f.ts.net`),
exposed via Tailscale Funnel. Testers do **not** need to be on the tailnet — it's
publicly reachable; local AI games work regardless. The backend runs on the titan
host (`/opt/cribbage-staging`) and deploys separately from this skill.

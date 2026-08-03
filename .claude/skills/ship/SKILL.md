---
name: ship
description: Commit and push changes with a well-crafted commit message. Use when the user says "ship", "ship it", "commit", "push", "commit and push", or "merge and push". Analyzes the diff, runs the right per-subproject checks, writes a commit message in this repo's style, commits, and pushes — merging a worktree branch into main first when that's where the work is.
---

Commit the current work with a clear message, verify it compiles, and push.

Cribbage Club is a monorepo with four sub-projects that build independently
(`src/` backend, `mobile/` Flutter, `web/` React, `engine/` Rust), so which
checks run depends entirely on what changed. And work usually happens on a
`claude/*` branch in a worktree, so "push" often means "merge to main, then
push."

## Step 1 — Assess state

Run in parallel:

1. `git status` (never `-uall`)
2. `git diff` and `git diff --cached`
3. `git log --oneline -10` — the house commit style
4. `git branch --show-current` and `git worktree list`

If the working tree is clean and nothing is staged, say so and stop.

Note which top-level directories the change touches — Step 3 depends on it.

## Step 2 — Stage

Stage files **by name**. Avoid `git add -A` / `git add .` unless the change
really is the whole tree and you have read every file in it.

**Never stage:**
- `mobile/dart_define/*.json` if it has gained anything beyond the API URL
- Any credential, keystore, `.p12`, `.mobileprovision`, or `ExportOptions.plist`
  change that embeds a team ID you did not intend to publish
- `.DS_Store`, `build/`, `.gradle/`, `node_modules/`, `Pods/`
- Generated files whose source you did not change — `*.freezed.dart`,
  `*.g.dart`, `engine/pkg/`, `mobile/lib/src/rust/frb_generated.dart`. Stage
  these **only** alongside the model or Rust change that regenerated them.

If a file's presence in the diff surprises you, ask before staging it.

## Step 3 — Checks

Run only the checks for directories that actually changed. Run them in parallel.

| Changed | Check |
|---|---|
| `mobile/` | `cd mobile && flutter analyze lib` |
| `src/` (backend) | `JAVA_HOME=/Users/gannon/Library/Java/JavaVirtualMachines/openjdk-22.0.2/Contents/Home ./gradlew compileKotlin` |
| `web/` | `cd web && npx tsc -b --noEmit` |
| `engine/` | `cd engine && cargo check` |

**Scope Flutter analysis to `lib`.** Bare `flutter analyze` reports ~90
pre-existing errors from vendored `rust_builder/cargokit/` and
`test_driver/integration_test.dart` that have nothing to do with your change and
will never be clean. `flutter analyze lib` is the signal. (This is also why
`mobile/scripts/test.sh` fails at its analyze step — it runs the bare form.)

**`flutter test` has 2 known failures** — `local_game_service_test.dart` and
`local_game_notifier_test.dart` can't load the Rust FFI library in the test
host. If you run tests, confirm the count is 26 pass / 2 fail and move on. If
you're unsure whether a failure is yours, `git stash` and re-run to compare.

Run `dart format` on Dart files you touched before committing — the repo is
formatted and an unformatted file makes the next diff noisy.

If a check fails, fix it, re-stage, and re-run. Don't commit around a failure.

## Step 4 — Write the message

**This repo does not use conventional commits.** Don't write
`feat(mobile): ...`. Match the existing history:

```
Rebuild the mobile game screen around a perimeter peg board
Replace bottom sheets and stock AlertDialogs with CcDialog
Persist and resume in-progress local AI games
Fix home screen layout shift by removing active games loading spinner
```

**Summary line:**
- Capitalized, imperative, no trailing period, no type prefix
- Under ~72 characters
- Name the thing that changed, specifically — "Replace app icon with peg-in-hole
  mark", not "Update assets"
- A semicolon can join two genuinely coupled changes:
  "Apply design language to auth and puzzle flows; add reusable CcDialog"

**Body** — include whenever the change isn't self-evident from the summary,
which for anything multi-file is most of the time. Wrap at ~72 columns. Explain
*why*, and call out anything a reader would otherwise have to reverse-engineer:
a constraint you worked around, a convention you chose between, a bug fixed in
passing. Bullets are fine for enumerating distinct changes.

End with the co-author trailer your session's instructions specify, e.g.:

```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Commit with a heredoc so the formatting survives:

```bash
git commit -F - <<'EOF'
Summary line

Body paragraph.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
```

Never `--amend` a commit that has been pushed.

## Step 5 — Push

**The main branch is `main`.** `main` is checked out in the main worktree at
`/Users/gannon/Development/CribbageClub`; feature work lives in
`.claude/worktrees/<name>` on a `claude/*` branch. Git will not let you check
out `main` in a second worktree, so run main-side git with `-C` or from the
main worktree directory.

**On `main` already:** `git push origin main`.

**On a `claude/*` branch** — the usual case. Confirm the user wants it on main
(they normally do; "ship it" implies it). Then:

```bash
git fetch origin
git -C /Users/gannon/Development/CribbageClub status --short   # must be clean
git -C /Users/gannon/Development/CribbageClub merge --ff-only claude/<branch>
git -C /Users/gannon/Development/CribbageClub push origin main
```

If `--ff-only` is refused, main has moved. Drop the flag and merge properly:

```bash
git -C /Users/gannon/Development/CribbageClub merge --no-ff claude/<branch>
```

**Resolving conflicts here needs judgment, not a default.** Both sides are real
work. Read what landed on main first (`git show <sha> --stat`) — a conflict
usually means someone refactored the same file, and the right resolution is
main's newer structure with your change re-applied on top of it, not one side
taken wholesale. Then re-run the Step 3 checks on the merged tree and build
before committing the merge. Say in the merge commit body which side won and
why. If you can't resolve it confidently, stop and show the user the conflict.

## Step 6 — Confirm

Report the commit hash, the branch state (`git status -sb` should show
`## main...origin/main` with no divergence), and one line on what shipped.

If the change was mobile-facing and the user will want it on their phone, offer
`/release` — it does not run automatically.

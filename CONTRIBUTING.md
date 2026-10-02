# Contributing

Small project, small rules.

## Set up

```sh
swift build
swift test
scripts/build-app.sh   # builds olusage.app (needed to try notifications and launch-at-login)
```

macOS 14+ and the Swift toolchain are all you need. Keep the app dependency-free.

## Where things live

- `Sources/OlusageCore`: pure, tested logic (`UsageParser`, `APIUsageParser`, `UsageAlerts`).
- `Sources/olusage`: the app (menu bar UI, sign-in window, usage sources, Keychain, notifications).

## If ollama.com changes

Neither data source is documented, so breakage is expected now and then. Fix the relevant parser and
add a test with a **hand-written or fully sanitised** sample (for the settings page, copy
`document.body.innerText` and remove personal details).

## Rules

- `swift build && swift test` must pass.
- Never commit keys, cookies or real API responses. See [SECURITY.md](SECURITY.md).
- Put new logic in `OlusageCore` with a test where you can; keep UI code thin.
- Add a line to `CHANGELOG.md` for user-visible changes.

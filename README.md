# macOllamaStatus

A tiny macOS menu bar widget that shows your **live** Ollama usage, read from
[ollama.com/settings](https://ollama.com/settings).

```
🦙 42%
```

Click it for each usage meter and when it resets.

> **Unofficial.** Not affiliated with or endorsed by Ollama. Ollama has no public usage API, so this
> reads the settings page and may break if that page changes.

## Install

Requires macOS 14+ and the Swift toolchain (Xcode or Command Line Tools).

```sh
git clone https://github.com/Jktfe/macOllamaStatus.git
cd macOllamaStatus
scripts/build-app.sh
open olusage.app
```

The app is ad-hoc signed, not notarised. If macOS blocks it, right-click `olusage.app` and choose
**Open**.

## Use

1. Click the 🦙 in the menu bar and choose **Sign in…**.
2. Sign in to Ollama in the window that opens. It closes itself once you reach your settings page.
3. Usage refreshes every 5 minutes (change it in the menu, or use **Refresh now**).

## Privacy

- You sign in on ollama.com's own page. The app never sees or stores your password.
- The login cookie stays in WebKit's storage on your Mac. **Sign out** deletes it.
- The only network traffic is to ollama.com (and its sign-in provider) to load your settings page.

## Develop

```sh
swift build
swift test
```

The parsing lives in `Sources/OlusageCore/UsageParser.swift` and is unit-tested. If the settings page
changes, update the parser and add a fixture to `Tests/`.

## Licence

MIT

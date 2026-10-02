# macOllamaStatus

**Know before you run out.** A tiny macOS menu bar app that shows your live
[Ollama Cloud](https://ollama.com) usage and warns you *before* you hit the limit.

```
🦙 42%          🦙 ⚠︎ 93%
```

- Menu bar percentage for your most-used meter (session / weekly), with every meter in the menu.
- Notifications at **75%, 90% and 100%**, once per crossing, and quiet when you launch it.
- Warning mark in the menu bar from 90%.
- Two ways in: sign in on ollama.com, or paste an API key (optional).
- Launch at login. No Dock icon. No dependencies.

> **Unofficial.** Not affiliated with or endorsed by Ollama. Ollama has no documented usage API, so
> this reads your settings page (or an undocumented endpoint) and may break if either changes.

## Install

Requires macOS 14+ and the Swift toolchain (Xcode or Command Line Tools).

```sh
git clone https://github.com/Jktfe/macOllamaStatus.git
cd macOllamaStatus
scripts/build-app.sh
open olusage.app
```

Move `olusage.app` to `/Applications` to keep it. It is ad-hoc signed, not notarised: if macOS
blocks it, right-click the app and choose **Open**. Notifications and launch-at-login need the
`.app` bundle (they do nothing under `swift run`).

## Use

**Sign in (default).** Click 🦙 → **Sign in…** and sign in on ollama.com (2FA popups work). The
window closes itself when you reach your settings page. Shows percentages **and reset times**.

**API key (optional).** Click 🦙 → **Use API key…**, paste a key from
[ollama.com/settings/keys](https://ollama.com/settings/keys). Sturdier than reading the page, but
the API gives percentages only, with no reset times. **Back to sign-in mode** removes the key.

Usage refreshes every 5 minutes (change it in the menu).

## Privacy and security

- Nothing is stored in the repo. You sign in on ollama.com's own page, so the app never sees your
  password; the login cookie stays in WebKit's storage on your Mac and **Sign out** deletes it.
- An API key is stored in your **macOS Keychain**, never in a file.
- The only network traffic is to ollama.com (and its sign-in provider).
- Developing? A local `.env` is git-ignored. Never commit keys.

## Develop

```sh
swift build
swift test
```

- `Sources/OlusageCore`: pure logic (page parser, API parser, alert thresholds), fully unit-tested.
- `Sources/olusage`: the app (menu bar UI, sign-in window, sources, Keychain, notifications).
- If ollama.com changes, update the parser and add a test using the new page text. See
  [CONTRIBUTING.md](CONTRIBUTING.md).

## Built with ANT

Built by the **ANT Colony Development team**: a small colony of Claude agents working together in a
shared ANT room, with a human steering. One agent hardened the parsers and alerts, another handled
the app, packaging and docs, and they reviewed and merged each other's work.

## Licence

MIT

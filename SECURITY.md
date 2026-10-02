# Security

olusage is an **unofficial** menu bar widget. It is not affiliated with or endorsed by Ollama.

## What is stored where

| Item | Where | Removed by |
| --- | --- | --- |
| Login cookie (sign-in mode) | WebKit's website data store on your Mac | **Sign out** |
| API key (API-key mode) | macOS login Keychain, service `olusage.ollama-api-key` | **Back to sign-in mode** / Keychain Access |
| Refresh interval | `UserDefaults` | deleting the app's preferences |
| Your password | Never seen or stored: you type it on ollama.com's own page | n/a |

Nothing is written to the repository or to plain-text files. The last usage reading is held in memory
only.

## Network

The app only talks to `ollama.com` (and its sign-in provider during login):

- **Sign-in mode** loads `https://ollama.com/settings` in a web view with your session cookie.
- **API-key mode** calls `GET https://ollama.com/api/usage` with `Authorization: Bearer <key>`.

There is no telemetry, analytics or third-party service.

## Caveats

- Both data sources are **undocumented** and may change or disappear without notice. Sign-in mode
  scrapes the settings page; API-key mode relies on an endpoint Ollama has not published. If either
  breaks, the app shows an error rather than guessing.
- The release build is **ad-hoc signed, not notarised**, so macOS may ask you to right-click and
  choose **Open** the first time.
- Use an API key you are happy to dedicate to this. Revoke it from your Ollama account if the Mac is
  lost or the key is exposed.

## For contributors

- Never commit keys, cookies or real API responses. A local `.env` is git-ignored; test fixtures must
  be hand-written or fully sanitised (no account details, model names or counts).
- Tests use made-up data only.

## Reporting a vulnerability

Please report security issues privately through GitHub's **Security → Report a vulnerability** on this
repository rather than opening a public issue.

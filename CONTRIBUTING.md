# Contributing

Small project, small rules:

- `swift build && swift test` must pass.
- The settings page has no stable API. If it changes, fix `UsageParser` and add a test with the new
  page text (copy `document.body.innerText` from a signed-in `/settings` page, with personal details
  removed).
- Keep the app dependency-free.

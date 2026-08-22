# Pre-release acceptance criteria

The 1.0 closed-test build is acceptable only when:

- Core route tracking works signed out and offline.
- AI analysis requires sign-in and enforces the Free monthly quota server-side.
- Pro entitlement unlocks the intended advanced features without relying on a local boolean.
- Cloud actions cannot alter local data on network failure.
- Repeated cloud restore does not intentionally duplicate matching routes.
- Google Play test purchase and restore are verified server-side.
- The signed AAB builds from the reproducible GitHub workflow.
- Privacy/terms/support/deletion information matches actual behavior.
- Store screenshots contain demo/test data, not customer or employer-sensitive route information.

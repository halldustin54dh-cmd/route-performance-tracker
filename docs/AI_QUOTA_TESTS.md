# AI quota tests

- Signed-out user cannot invoke secure AI analysis and is told to sign in; local OCR/manual route entry remains available.
- Signed-in Free user can complete analyses 1, 2, and 3 during the same calendar month.
- Analysis 4 is rejected before another provider call is made.
- Free quota is account/server based and does not reset after reinstalling or clearing local app storage.
- Active Pro account is not blocked by the Free monthly quota.
- Pro remains subject to request-rate/abuse protection.
- Expired/inactive Pro entitlement falls back to Free behavior.
- AI request failure does not corrupt route setup or stored screenshots.

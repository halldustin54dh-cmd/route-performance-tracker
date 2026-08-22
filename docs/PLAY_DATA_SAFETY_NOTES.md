# Google Play Data Safety preparation notes

Complete the Play Console Data Safety form from the final production behavior, not assumptions. Re-check this document immediately before submission.

Current release design processes:
- Account email through Supabase Auth.
- User-entered route/checkpoint/event/performance data.
- User-selected screenshots/photos stored locally; resized analysis copies may be sent for user-requested AI analysis.
- Cloud-backed route/checkpoint/event data for Pro users.
- Subscription identifiers/status for entitlement verification.
- Operational/security metadata necessary to run the backend.

Current design does not intentionally sell route data to advertisers or upload original evidence images as part of route cloud backup.

Questions to verify before submitting the Data Safety form:
1. Which data categories Google classifies each field under.
2. Whether data is collected, shared, ephemeral, optional, or required under Google's current definitions.
3. Encryption in transit for every network path.
4. Account/data deletion mechanism and public deletion URL.
5. Whether any analytics/crash-reporting SDK has been added since this document was written.
6. AI provider processing classification under Google's current guidance.

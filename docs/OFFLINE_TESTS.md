# Offline behavior tests

- App launches with existing local data while offline.
- New route setup can be saved offline.
- First stop, checkpoints, events, and evidence metadata save offline.
- Forecast/history using local data continues offline.
- AI analysis clearly requires connectivity and does not block manual entry.
- Sign-in/account/cloud actions fail gracefully when offline.
- A failed cloud backup/restore never deletes or rewrites local route data.
- Returning online and retrying cloud actions succeeds without app restart when practical.
- Subscription verification outage does not falsely grant or permanently revoke local route access.

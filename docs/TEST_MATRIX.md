# Release test matrix

| Area | Free signed out | Free signed in | Pro signed in | Offline |
|---|---|---|---|---|
| Local route tracking | Yes | Yes | Yes | Yes |
| Checkpoints/events/evidence | Yes | Yes | Yes | Yes |
| Basic forecast/stats | Yes | Yes | Yes | Yes |
| 7-day basic analytics | Yes | Yes | Yes | Yes |
| AI analysis | No | 3/month | Expanded/fair-use | No |
| Advanced analytics | No | No | Yes | Cached/local data only after entitlement can be confirmed |
| Cloud backup/restore | No | No | Yes | No |
| Subscription purchase/restore | No | Yes | Yes | No |

Regression testing should exercise every supported state before release. Network-only actions must fail without corrupting or deleting local route data.

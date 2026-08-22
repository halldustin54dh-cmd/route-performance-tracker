# Real-route regression scenarios

These scenarios are based on previously recorded delivery-day patterns and exist to catch forecast and pace regressions before release.

## Scenario A — steady urban/suburban route
- First stop: 10:58 AM
- Checkpoints: stop 36 at 11:33 AM, stop 49 at 12:33 PM, stop 77 at 1:33 PM, stop 95 at 2:38 PM, stop 147 at 4:42 PM, stop 168 at 5:32 PM
- Final stop: 193 at 6:22 PM
- Include a documented backtrack/access delay around the middle of the route.

Expected behavior: cumulative pace and adjusted pace remain distinct; a documented delay should not make adjusted performance look worse than raw pace; final-stop forecasting should become more stable as later checkpoints accumulate.

## Scenario B — lower-stop route with longer travel
- First stop: 11:11 AM after a substantial drive to route
- Checkpoints: stop 15 at 12:18 PM, 40 at 1:11 PM, 62 at 2:10 PM, 81 at 3:11 PM, 94 at 4:12 PM, 106 at 5:13 PM
- Final stop: 125 at 6:28 PM

Expected behavior: pre-route travel must not contaminate delivery pace; fewer stops must not automatically imply an easy route; forecast should reflect today's pace instead of assuming a universal stop rate.

## Scenario C — dense route with operational friction
- First stop: 10:47 AM
- Checkpoints should include an early wrong-address/navigation delay and multiple closely spaced stops.
- Ensure two listed stops that are physically the same delivery location do not create nonsensical manual-delay assumptions.

Expected behavior: route difficulty should use density/travel/context rather than raw stop count alone; documented navigation delay should be visible in event history and adjusted metrics.

## Scenario D — late-day checkpoint stability
Use a route with checkpoints approximately one hour apart through the afternoon and compare each predicted finish time with the known final-stop time.

Expected behavior: forecast confidence should increase rather than decrease as useful checkpoints accumulate, absent a newly logged disruption; no forecast should display when there is not enough information.

## Required regression assertions
- No missing optional field produces a fake “easy” score.
- No divide-by-zero/Infinity/NaN values appear.
- Stops remaining never becomes negative.
- Forecast never precedes the latest checkpoint time.
- A route completed locally remains accessible after sign-out.
- Repeated cloud restore does not intentionally duplicate the same backed-up route.

# Real Route Forecast Backtests

This project includes a small anonymized regression dataset built from manually logged delivery-route checkpoints.

## Included routes

| Date | Stops | First stop | Final stop | Notes |
| --- | ---: | --- | --- | --- |
| 2026-08-13 | 125 | 11:11 AM | 6:28 PM | Dense checkpoint history |
| 2026-08-14 | 193 | 10:33 AM | 6:22 PM | Includes 14 documented delay minutes and a known prior historical pace baseline |
| 2026-08-15 | 166 | 10:58 AM | 7:43 PM | Includes documented road-closure context |
| 2026-08-20 | 184 | 10:47 AM | 6:44 PM | Includes a 10-minute wrong-address delay and a known prior historical pace baseline |

Only fields actually supported by the logs are populated. Unknown package/location counts and uncertain context are intentionally left unset rather than invented.

## What the test does

For every eligible checkpoint, the test reconstructs the route exactly as it would have looked at that moment, withholding all later checkpoints and the actual finish time from the forecast engine. It then records the projected finish and compares it with the known final-stop time.

The test suite currently checks that:

- every eligible checkpoint produces a forecast;
- forecasts become materially more accurate later in the route;
- late-route mean absolute error remains below a regression ceiling;
- an accuracy report can be printed for model tuning.

These assertions are regression guards, not a claim that the current forecasting algorithm is production-accurate. The dataset is specifically intended to expose where the model is weak so the weights and future features can be tuned against real behavior rather than synthetic examples.

## Verified benchmark

GitHub Actions ran the same four historical routes against both the original and stabilized forecast behavior.

| Model | Overall checkpoint MAE |
| --- | ---: |
| Original unsmoothed forecast | 78.3 min |
| Adjusted + smoothed forecast | 63.4 min |

That is a 19.0% reduction in mean absolute forecast error on the current fixture set.

Current per-route MAE after stabilization:

| Route | MAE |
| --- | ---: |
| 2026-08-13 | 62.8 min |
| 2026-08-14 | 33.0 min |
| 2026-08-15 | 80.5 min |
| 2026-08-20 | 65.6 min |

The 2026-08-15 route remains the clearest weak case. Its pace changes sharply across the day, so it is useful evidence that future forecasting should understand route phase and context rather than simply increasing the weight of the most recent segment.

## Current stabilization changes

- use documented-delay-adjusted cumulative pace for the forecast baseline;
- smooth recent pace across up to three checkpoints;
- subtract documented delay from the recent rolling window;
- clamp recent pace to 70%–130% of the cumulative pace so one freak segment cannot move the finish estimate by hours;
- reduce recent-segment weight and rely more heavily on cumulative route behavior;
- keep historical pace as a modest input when a known baseline exists.

## Next tuning targets

- model route progress bands so early-route estimates carry different behavior and confidence than late-route estimates;
- weight historical pace by route similarity and sample size;
- incorporate route type, travel density, apartments/businesses, and other verified context when available;
- distinguish genuinely slow route sections from one-off delays;
- expand the fixture set as more verified route logs are available.

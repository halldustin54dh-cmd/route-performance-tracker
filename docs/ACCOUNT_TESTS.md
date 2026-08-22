# Account behavior tests

## Sign up
- Valid email/password creates account or clearly indicates email confirmation if required.
- Invalid/empty credentials do not crash.
- Weak/no network fails without touching local route data.

## Sign in/out
- Password sign-in restores account session.
- Sign-out removes cloud/account session only; local routes remain.
- Signing back in does not duplicate local routes.

## Cloud backup/restore
- Free account receives a Pro-required message.
- Pro account can back up completed routes.
- Network failure leaves local data unchanged.
- Repeating backup updates the same cloud route identity rather than multiplying records.
- Clean device can restore route/checkpoint/event data.
- Repeating restore does not intentionally duplicate a matching route.
- Original evidence image bytes are not falsely claimed to be restored.

# Data deletion instructions — Draft

Before public release, publish these instructions at a stable public URL and ensure the in-app account screen links to them.

## Local route data
Local route data is stored on the device. Removing local routes in the app, clearing the app's storage, or uninstalling the app may remove locally stored information depending on platform behavior. Cloud backups are separate from local data.

## Cloud route data
Signed-in users can request deletion of their cloud route records and account data through the published support/privacy contact until an in-app self-service deletion flow is available. The final production release should provide a self-service account deletion action where practical.

## Subscription data
Deleting a Route Performance Tracker account does not by itself cancel an app-store subscription. Users must manage or cancel subscriptions through Google Play or the applicable app store. Certain purchase/transaction records may remain with the app store as required by its terms or law.

## AI processing
Route screenshot analysis sends temporary analysis inputs through the secure backend to the configured AI provider with provider-side storage disabled for these requests. Operational/security logs should not contain image contents.

## Evidence files
Original evidence image files are stored locally in the current release design and are not included in route cloud backup. Removing local evidence or app storage may remove those files from the app-controlled storage area.

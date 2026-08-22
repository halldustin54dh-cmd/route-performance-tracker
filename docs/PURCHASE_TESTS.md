# Purchase verification tests

- Purchase UI uses Google Play product details/localized price.
- Monthly and annual IDs exactly match backend allow-list.
- User must be signed in before server activation.
- Successful store purchase is not acknowledged as Pro until backend verification succeeds.
- Backend verifies purchase token with Google Play and product ID matches allowed product.
- Active/grace subscription creates or refreshes active Pro entitlement.
- Invalid/inactive token cannot grant Pro.
- Restore purchase replays verification and restores Pro to the signed-in account.
- Expired entitlement is treated as Free.
- Temporary verification outage shows a recoverable error and does not fabricate Pro access.

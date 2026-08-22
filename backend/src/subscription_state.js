function hasFutureExpiry(item, nowMs = Date.now()) {
  if (!item?.expiryTime) return false;
  const expiry = Date.parse(item.expiryTime);
  return Number.isFinite(expiry) && expiry > nowMs;
}

export function isEntitledSubscription(state, item, nowMs = Date.now()) {
  if (!item) return false;
  return state === 'SUBSCRIPTION_STATE_ACTIVE' ||
    state === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' ||
    (state === 'SUBSCRIPTION_STATE_CANCELED' && hasFutureExpiry(item, nowMs));
}

import test from 'node:test';
import assert from 'node:assert/strict';
import { isEntitledSubscription } from '../vercel/api/verify-google-play.js';

const now = Date.parse('2026-08-22T00:00:00Z');
const futureItem = { expiryTime: '2026-09-22T00:00:00Z' };
const expiredItem = { expiryTime: '2026-08-21T00:00:00Z' };

test('active subscription is entitled', () => {
  assert.equal(isEntitledSubscription('SUBSCRIPTION_STATE_ACTIVE', futureItem, now), true);
});

test('grace-period subscription remains entitled', () => {
  assert.equal(isEntitledSubscription('SUBSCRIPTION_STATE_IN_GRACE_PERIOD', futureItem, now), true);
});

test('voluntarily canceled subscription remains entitled until expiry', () => {
  assert.equal(isEntitledSubscription('SUBSCRIPTION_STATE_CANCELED', futureItem, now), true);
  assert.equal(isEntitledSubscription('SUBSCRIPTION_STATE_CANCELED', expiredItem, now), false);
});

test('expired, paused, and on-hold states are not entitled', () => {
  for (const state of [
    'SUBSCRIPTION_STATE_EXPIRED',
    'SUBSCRIPTION_STATE_PAUSED',
    'SUBSCRIPTION_STATE_ON_HOLD',
    'SUBSCRIPTION_STATE_PENDING',
  ]) {
    assert.equal(isEntitledSubscription(state, futureItem, now), false, state);
  }
});

test('missing matching line item cannot grant entitlement', () => {
  assert.equal(isEntitledSubscription('SUBSCRIPTION_STATE_ACTIVE', null, now), false);
});

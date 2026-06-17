/**
 * Testes manuais para subscription-access (node --import tsx).
 * Executar: npx tsx scripts/test-subscription-access.ts
 */
import assert from 'node:assert/strict';
import {
  accessFromEffectiveStatus,
  computeEffectiveStatus,
} from '../src/lib/subscription-access';

const now = new Date('2026-06-15T12:00:00.000Z').getTime();

// Plano gratuito sem ends_at
assert.equal(
  computeEffectiveStatus(
    { status: 'active', ends_at: null, grace_period_ends_at: null, deletion_scheduled_at: null },
    'basico',
    now,
  ),
  'active',
);

// Expirou há 3 dias → grace
assert.equal(
  computeEffectiveStatus(
    {
      status: 'active',
      ends_at: '2026-06-12T00:00:00.000Z',
      grace_period_ends_at: null,
      deletion_scheduled_at: null,
    },
    'pro',
    now,
  ),
  'grace_period',
);

// Expirou há 10 dias → restricted
assert.equal(
  computeEffectiveStatus(
    {
      status: 'restricted',
      ends_at: '2026-06-05T00:00:00.000Z',
      grace_period_ends_at: null,
      deletion_scheduled_at: null,
    },
    'pro',
    now,
  ),
  'restricted',
);

const restricted = accessFromEffectiveStatus('restricted', false);
assert.equal(restricted.canUpload, false);
assert.equal(restricted.canDownload, true);
assert.equal(restricted.blockReason, 'subscription_restricted');

const overQuota = accessFromEffectiveStatus('active', true);
assert.equal(overQuota.canUpload, false);
assert.equal(overQuota.storageOverQuota, true);

console.log('subscription-access: ok');

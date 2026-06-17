import { runSubscriptionLifecycle } from '../db/subscriptions';
import type { Env } from '../types';

export async function runSubscriptionLifecycleJob(env: Env): Promise<void> {
  const result = await runSubscriptionLifecycle(env.DB, env.FILES_BUCKET);

  console.log(
    JSON.stringify({
      event: 'subscription_lifecycle_complete',
      environment: env.ENVIRONMENT ?? 'unknown',
      ...result,
    }),
  );
}

import type { UserProfile } from '../db/schema';

export type MeProfileResponse = UserProfile & {
  maxFileSizeBytes: number;
  quotaBytesOverride: number | null;
  maxFileSizeBytesOverride: number | null;
};

export function buildMeProfileResponse(
  profile: UserProfile,
  overrides: {
    quotaBytesOverride: number | null;
    maxFileSizeBytesOverride: number | null;
  },
): MeProfileResponse {
  return {
    ...profile,
    maxFileSizeBytes: profile.plan.maxFileSizeBytes,
    quotaBytesOverride: overrides.quotaBytesOverride,
    maxFileSizeBytesOverride: overrides.maxFileSizeBytesOverride,
  };
}

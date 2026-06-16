import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';

const FIREBASE_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const jwks = createRemoteJWKSet(new URL(FIREBASE_JWKS_URL));

export type FirebaseTokenPayload = JWTPayload & {
  email?: string;
  email_verified?: boolean;
  name?: string;
  picture?: string;
};

/**
 * Valida ID token Firebase (JWKS publico — sem service account).
 */
export async function verifyFirebaseIdToken(
  token: string,
  projectId: string,
): Promise<FirebaseTokenPayload> {
  const { payload } = await jwtVerify(token, jwks, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });

  if (!payload.sub) {
    throw new Error('Token sem subject (uid)');
  }

  return payload as FirebaseTokenPayload;
}

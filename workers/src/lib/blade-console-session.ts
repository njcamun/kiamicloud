import { SignJWT, jwtVerify } from 'jose';

export const BLADE_CONSOLE_COOKIE = 'kiamicloud_blade_session';
const SESSION_TTL = '12h';
const SESSION_MAX_AGE_SEC = 12 * 60 * 60;

function sessionKey(user: string, password: string): Uint8Array {
  return new TextEncoder().encode(`${user}:${password}:kiamicloud-blade-v2`);
}

export async function createBladeConsoleSession(
  user: string,
  password: string,
): Promise<string> {
  return new SignJWT({ role: 'blade-console', user })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(SESSION_TTL)
    .sign(sessionKey(user, password));
}

export async function verifyBladeConsoleSession(
  token: string,
  user: string,
  password: string,
): Promise<boolean> {
  try {
    const { payload } = await jwtVerify(token, sessionKey(user, password));
    return payload.role === 'blade-console';
  } catch {
    return false;
  }
}

export { SESSION_MAX_AGE_SEC };

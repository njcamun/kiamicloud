/** UIDs Firebase com acesso /admin (virgula em ADMIN_UIDS). */
export function parseAdminUids(raw: string | undefined): Set<string> {
  if (!raw?.trim()) return new Set();
  return new Set(
    raw
      .split(',')
      .map((u) => u.trim())
      .filter(Boolean),
  );
}

export function isAdminUid(uid: string, raw: string | undefined): boolean {
  return parseAdminUids(raw).has(uid);
}

/** Apaga objectos R2 ignorando chaves nulas e erros isolados. */
export async function deleteR2Objects(
  bucket: R2Bucket,
  keys: Iterable<string | null | undefined>,
): Promise<void> {
  const unique = [
    ...new Set(
      [...keys].filter((k): k is string => typeof k === 'string' && k.length > 0),
    ),
  ];

  await Promise.all(
    unique.map(async (key) => {
      try {
        await bucket.delete(key);
      } catch (err) {
        console.error('[r2-delete]', key, err);
      }
    }),
  );
}

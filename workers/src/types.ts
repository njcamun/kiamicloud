/** Utilizador autenticado (extraido do JWT Firebase). */

export type AuthUser = {

  uid: string;

  email?: string;

  emailVerified?: boolean;

  name?: string;

  picture?: string;

};



export type Env = {

  FIREBASE_PROJECT_ID: string;

  ENVIRONMENT?: string;

  DB: D1Database;

  FILES_BUCKET: R2Bucket;

  R2_BUCKET_NAME: string;

  R2_PRESIGN_EXPIRES_SECONDS?: string;

  /** API tokens R2 (secrets — ver docs/R2_SETUP.md) */

  R2_ACCOUNT_ID?: string;

  R2_ACCESS_KEY_ID?: string;

  R2_SECRET_ACCESS_KEY?: string;

  /** Origens CORS extra (virgula), ex.: https://app.kiamicloud.com */
  API_ALLOWED_ORIGINS?: string;

  /** Segredo do webhook de pagamento (Fase 12) */
  PAYMENT_WEBHOOK_SECRET?: string;

  /** "false" desactiva POST /billing/checkout */
  PAYMENTS_ENABLED?: string;

  /** UIDs Firebase admin (virgula) — Fase 13 */
  ADMIN_UIDS?: string;

  /** Password da consola Blade (apenas ENVIRONMENT=development, LAN) */
  BLADE_CONSOLE_PASSWORD?: string;

  /** Utilizador da consola Blade (development, default admin) */
  BLADE_CONSOLE_USER?: string;

};



export type AppVariables = {

  user: AuthUser;

};



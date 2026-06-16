import { insertAccountEvent } from './account_events';
import { ensureSupportChatSchema } from './support_chat_schema';

export type SupportMessageDto = {
  id: string;
  senderRole: 'user' | 'admin';
  message: string;
  createdAt: string;
  legacy?: boolean;
};

type ChatRow = {
  id: number;
  firebase_uid: string;
  sender_role: 'user' | 'admin';
  sender_uid: string | null;
  message: string;
  created_at: string;
};

type LegacyRow = {
  id: number;
  message: string;
  created_at: string;
};

type ReadStateRow = {
  user_last_read_id: number;
  admin_last_read_id: number;
};

function mapChatRow(row: ChatRow): SupportMessageDto {
  return {
    id: `msg-${row.id}`,
    senderRole: row.sender_role,
    message: row.message,
    createdAt: row.created_at,
  };
}

function mapLegacyRow(row: LegacyRow): SupportMessageDto {
  return {
    id: `legacy-${row.id}`,
    senderRole: 'user',
    message: row.message,
    createdAt: row.created_at,
    legacy: true,
  };
}

async function getReadState(
  db: D1Database,
  firebaseUid: string,
): Promise<ReadStateRow> {
  const row = await db
    .prepare(
      `SELECT user_last_read_id, admin_last_read_id
       FROM support_chat_read_state WHERE firebase_uid = ?`,
    )
    .bind(firebaseUid)
    .first<ReadStateRow>();
  return row ?? { user_last_read_id: 0, admin_last_read_id: 0 };
}

async function ensureReadState(db: D1Database, firebaseUid: string): Promise<void> {
  await db
    .prepare(
      `INSERT OR IGNORE INTO support_chat_read_state (firebase_uid)
       VALUES (?)`,
    )
    .bind(firebaseUid)
    .run();
}

async function listLegacyMessages(
  db: D1Database,
  firebaseUid: string,
): Promise<SupportMessageDto[]> {
  const { results } = await db
    .prepare(
      `SELECT id, message, created_at
       FROM beta_feedback
       WHERE firebase_uid = ?
       ORDER BY created_at ASC`,
    )
    .bind(firebaseUid)
    .all<LegacyRow>();
  return (results ?? []).map(mapLegacyRow);
}

async function listChatMessages(
  db: D1Database,
  firebaseUid: string,
): Promise<SupportMessageDto[]> {
  const { results } = await db
    .prepare(
      `SELECT id, firebase_uid, sender_role, sender_uid, message, created_at
       FROM support_chat_messages
       WHERE firebase_uid = ?
       ORDER BY created_at ASC, id ASC`,
    )
    .bind(firebaseUid)
    .all<ChatRow>();
  return (results ?? []).map(mapChatRow);
}

function mergeMessages(
  legacy: SupportMessageDto[],
  chat: SupportMessageDto[],
): SupportMessageDto[] {
  const merged = [...legacy, ...chat];
  merged.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  return merged;
}

function numericMessageId(id: string): number {
  const match = /^msg-(\d+)$/.exec(id);
  return match ? Number(match[1]) : 0;
}

export async function listSupportMessagesForUser(
  db: D1Database,
  firebaseUid: string,
): Promise<{ messages: SupportMessageDto[]; unreadCount: number }> {
  await ensureSupportChatSchema(db);
  const [legacy, chat, readState] = await Promise.all([
    listLegacyMessages(db, firebaseUid),
    listChatMessages(db, firebaseUid),
    getReadState(db, firebaseUid),
  ]);
  const messages = mergeMessages(legacy, chat);
  const unreadCount = chat.filter(
    (m) =>
      m.senderRole === 'admin' &&
      numericMessageId(m.id) > readState.user_last_read_id,
  ).length;
  return { messages, unreadCount };
}

export async function listSupportMessagesForAdmin(
  db: D1Database,
  firebaseUid: string,
): Promise<{ messages: SupportMessageDto[]; unreadCount: number }> {
  return listSupportMessagesForUser(db, firebaseUid).then(async (result) => {
    const readState = await getReadState(db, firebaseUid);
    const chat = await listChatMessages(db, firebaseUid);
    const legacyPending = await db
      .prepare(
        `SELECT COUNT(*) AS c FROM beta_feedback
         WHERE firebase_uid = ? AND reviewed_at IS NULL`,
      )
      .bind(firebaseUid)
      .first<{ c: number }>();
    const unreadFromChat = chat.filter(
      (m) =>
        m.senderRole === 'user' &&
        numericMessageId(m.id) > readState.admin_last_read_id,
    ).length;
    return {
      messages: result.messages,
      unreadCount: unreadFromChat + (legacyPending?.c ?? 0),
    };
  });
}

export async function sendSupportMessageAsUser(
  db: D1Database,
  input: { firebaseUid: string; senderUid: string; message: string },
): Promise<SupportMessageDto> {
  await ensureSupportChatSchema(db);
  await ensureReadState(db, input.firebaseUid);
  const insert = await db
    .prepare(
      `INSERT INTO support_chat_messages (
         firebase_uid, sender_role, sender_uid, message
       ) VALUES (?, 'user', ?, ?)`,
    )
    .bind(input.firebaseUid, input.senderUid, input.message)
    .run();

  const rowId = Number(insert.meta.last_row_id);
  const result = await db
    .prepare(
      `SELECT id, firebase_uid, sender_role, sender_uid, message, created_at
       FROM support_chat_messages WHERE id = ?`,
    )
    .bind(rowId)
    .first<ChatRow>();

  if (!result) {
    throw new Error('Falha ao guardar mensagem.');
  }

  await insertAccountEvent(db, {
    firebaseUid: input.firebaseUid,
    kind: 'support_sent',
    title: 'Mensagem de suporte',
    body:
      input.message.length > 120
        ? `${input.message.slice(0, 117)}…`
        : input.message,
    metadata: { messageId: result.id },
    markRead: true,
  });

  return mapChatRow(result);
}

export async function sendSupportMessageAsAdmin(
  db: D1Database,
  input: { firebaseUid: string; adminUid: string; message: string },
): Promise<SupportMessageDto> {
  await ensureSupportChatSchema(db);
  await ensureReadState(db, input.firebaseUid);
  const insert = await db
    .prepare(
      `INSERT INTO support_chat_messages (
         firebase_uid, sender_role, sender_uid, message
       ) VALUES (?, 'admin', ?, ?)`,
    )
    .bind(input.firebaseUid, input.adminUid, input.message)
    .run();

  const rowId = Number(insert.meta.last_row_id);
  const result = await db
    .prepare(
      `SELECT id, firebase_uid, sender_role, sender_uid, message, created_at
       FROM support_chat_messages WHERE id = ?`,
    )
    .bind(rowId)
    .first<ChatRow>();

  if (!result) {
    throw new Error('Falha ao guardar resposta.');
  }

  await insertAccountEvent(db, {
    firebaseUid: input.firebaseUid,
    kind: 'support_reviewed',
    title: 'Resposta do suporte',
    body:
      input.message.length > 120
        ? `${input.message.slice(0, 117)}…`
        : input.message,
    metadata: { messageId: result.id },
    markRead: false,
  });

  return mapChatRow(result);
}

async function maxChatMessageId(
  db: D1Database,
  firebaseUid: string,
): Promise<number> {
  const row = await db
    .prepare(
      `SELECT COALESCE(MAX(id), 0) AS max_id
       FROM support_chat_messages WHERE firebase_uid = ?`,
    )
    .bind(firebaseUid)
    .first<{ max_id: number }>();
  return row?.max_id ?? 0;
}

export async function markSupportReadByUser(
  db: D1Database,
  firebaseUid: string,
): Promise<void> {
  await ensureSupportChatSchema(db);
  await ensureReadState(db, firebaseUid);
  const maxId = await maxChatMessageId(db, firebaseUid);
  await db
    .prepare(
      `UPDATE support_chat_read_state
       SET user_last_read_id = ?
       WHERE firebase_uid = ?`,
    )
    .bind(maxId, firebaseUid)
    .run();
}

export async function markSupportReadByAdmin(
  db: D1Database,
  firebaseUid: string,
): Promise<void> {
  await ensureSupportChatSchema(db);
  await ensureReadState(db, firebaseUid);
  const maxId = await maxChatMessageId(db, firebaseUid);
  await db
    .prepare(
      `UPDATE support_chat_read_state
       SET admin_last_read_id = ?
       WHERE firebase_uid = ?`,
    )
    .bind(maxId, firebaseUid)
    .run();
  await db
    .prepare(
      `UPDATE beta_feedback
       SET reviewed_at = datetime('now')
       WHERE firebase_uid = ? AND reviewed_at IS NULL`,
    )
    .bind(firebaseUid)
    .run();
}

export async function countUnreadSupportForUser(
  db: D1Database,
  firebaseUid: string,
): Promise<number> {
  const { unreadCount } = await listSupportMessagesForUser(db, firebaseUid);
  return unreadCount;
}

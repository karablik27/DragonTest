import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {v4 as uuid} from "uuid";

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

/**
 * Устанавливает/мерджит кастомный claim пользователю.
 * @param {string} uid Пользовательский UID
 * @param {string} key Имя claim
 * @param {unknown} value Значение claim
 * @return {Promise<void>}
 */
async function setClaim(
  uid: string,
  key: string,
  value: unknown,
): Promise<void> {
  const user = await auth.getUser(uid);
  const claims = (user.customClaims ?? {}) as Record<string, unknown>;
  claims[key] = value;
  await auth.setCustomUserClaims(uid, claims);
}

/**
 * Старт/перехват сессии (единственная активная на аккаунт).
 */
export const startSession = functions.https.onCall(async (request) => {
  const payload = (request.data ?? {}) as {
    uid: string; deviceId: string; force?: boolean;
  };

  const uid = payload.uid || "";
  const deviceId = payload.deviceId || "";
  const force = Boolean(payload.force);

  if (!request.auth || request.auth.uid !== uid) {
    throw new functions.https.HttpsError("unauthenticated", "Not authorized");
  }
  if (!uid || !deviceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "uid and deviceId are required",
    );
  }

  const sessionRef = db.collection("sessions").doc(uid);
  const snap = await sessionRef.get();

  if (snap.exists) {
    const current = snap.data() as {activeDeviceId?: string}|undefined;
    const active = current?.activeDeviceId;
    if (active && active !== deviceId && !force) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "SESSION_CONFLICT",
      );
    }
  }

  const sessionId = uuid();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await sessionRef.set(
    {
      activeDeviceId: deviceId,
      sessionId: sessionId,
      startedAt: now,
      updatedAt: now,
      reason: force ? "taken_over" : "login",
    },
    {merge: true},
  );

  await setClaim(uid, "sid", sessionId);
  await auth.revokeRefreshTokens(uid);

  return {sessionId: sessionId};
});

/**
 * Завершение сессии для текущего deviceId.
 */
export const endSession = functions.https.onCall(async (request) => {
  const payload = (request.data ?? {}) as {uid: string; deviceId: string};

  const uid = payload.uid || "";
  const deviceId = payload.deviceId || "";

  if (!request.auth || request.auth.uid !== uid) {
    throw new functions.https.HttpsError("unauthenticated", "Not authorized");
  }
  if (!uid || !deviceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "uid and deviceId are required",
    );
  }

  const sessionRef = db.collection("sessions").doc(uid);
  const snap = await sessionRef.get();

  if (snap.exists) {
    const current = snap.data() as {activeDeviceId?: string}|undefined;
    if (current?.activeDeviceId === deviceId) {
      await sessionRef.set(
        {
          sessionId: "",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          reason: "logout",
        },
        {merge: true},
      );
    }
  }

  await auth.revokeRefreshTokens(uid);
  return {ok: true};
});

import * as admin from "firebase-admin";
import {beforeUserSignedIn} from "firebase-functions/v2/identity";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";

admin.initializeApp();

/** Block users whose email is not verified */
export const blockUnverified = beforeUserSignedIn((event) => {
  const u = event.data;
  const hasEmail = !!u?.email;
  const verified = !!u?.emailVerified;

  if (hasEmail && !verified) {
    throw new HttpsError(
      "permission-denied",
      "Verify your email before signing in."
    );
  }
});

/** Callable to resend the verification email */
export const resendVerificationEmail = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const rec = await admin.auth().getUser(uid);
  if (!rec.email) throw new HttpsError("failed-precondition", "No email.");
  if (rec.emailVerified) return {message: "Already verified."};

  const acs: admin.auth.ActionCodeSettings = {
    url: "https://pawpal-de6dd.firebaseapp.com/",
    handleCodeInApp: true,
  };

  const link = await admin.auth().generateEmailVerificationLink(rec.email, acs);
  return {message: "Verification email sent.", link};
});

/**
 * Set a user's role (0=user, 1=admin) and mirror to custom claims.
 * Only callable by an existing admin (custom claim admin=true).
 */
const SEED_ADMINS = new Set<string>([
  // Add your bootstrap admin emails here (server-side only)
  "admin@pawpal.app",
]);

export const setUserRole = onCall(async (request) => {
  const caller = request.auth;
  if (!caller?.uid) throw new HttpsError("unauthenticated", "Sign in first.");
  let isAdmin = !!caller.token?.admin;
  const email = (caller.token?.email as string | undefined)?.toLowerCase();
  // Bootstrap path: seeded admin email OR role==1 in Firestore
  if (!isAdmin && (!email || !SEED_ADMINS.has(email))) {
    const db = getFirestore();
    try {
      const snap = await db.collection("users").doc(caller.uid).get();
      const role = (snap.data()?.role as number | undefined) ?? 0;
      isAdmin = role === 1;
    } catch {
      isAdmin = false;
    }
    if (!isAdmin) {
      throw new HttpsError("permission-denied", "Admins only.");
    }
  }

  const uid = request.data?.uid as string | undefined;
  const role = request.data?.role as number | undefined; // 0 or 1
  if (!uid || (role !== 0 && role !== 1)) {
    throw new HttpsError("invalid-argument", "Provide {uid, role: 0|1}");
  }

  // Prevent an admin from removing their own admin rights
  if (uid === caller.uid && role !== 1) {
    throw new HttpsError(
      "failed-precondition",
      "You cannot remove your own admin role."
    );
  }

  // Update custom claims
  await admin.auth().setCustomUserClaims(uid, {admin: role === 1});

  // Mirror to Firestore
  const db = getFirestore();
  await db.collection("users").doc(uid).set({
    role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {ok: true};
});

/**
 * Permanently delete a user's account and profile document.
 * Only callable by an admin (custom claim admin=true) or a seeded email.
 */
export const deleteUserAccount = onCall(async (request) => {
  const caller = request.auth;
  if (!caller?.uid) throw new HttpsError("unauthenticated", "Sign in first.");
  let isAdmin = !!caller.token?.admin;
  const email = (caller.token?.email as string | undefined)?.toLowerCase();
  if (!isAdmin && (!email || !SEED_ADMINS.has(email))) {
    const db = getFirestore();
    try {
      const snap = await db.collection("users").doc(caller.uid).get();
      const role = (snap.data()?.role as number | undefined) ?? 0;
      isAdmin = role === 1;
    } catch {
      isAdmin = false;
    }
    if (!isAdmin) {
      throw new HttpsError("permission-denied", "Admins only.");
    }
  }

  const uid = request.data?.uid as string | undefined;
  if (!uid) throw new HttpsError("invalid-argument", "Provide {uid}");

  // Prevent an admin from deleting themselves accidentally
  if (uid === caller.uid) {
    throw new HttpsError("failed-precondition", "You cannot delete your own account.");
  }

  const db = getFirestore();

  // Best-effort: remove Firestore profile first, then delete auth user.
  try {
    await db.collection("users").doc(uid).delete();
  } catch (e) {
    // ignore Firestore delete failures here; proceed to delete auth user
  }

  await admin.auth().deleteUser(uid);

  return {ok: true};
});

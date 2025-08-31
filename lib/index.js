"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUserAccount = exports.setUserRole = exports.resendVerificationEmail = exports.blockUnverified = void 0;
const admin = __importStar(require("firebase-admin"));
const identity_1 = require("firebase-functions/v2/identity");
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
admin.initializeApp();
/** Block users whose email is not verified */
exports.blockUnverified = (0, identity_1.beforeUserSignedIn)((event) => {
    const u = event.data;
    const hasEmail = !!(u === null || u === void 0 ? void 0 : u.email);
    const verified = !!(u === null || u === void 0 ? void 0 : u.emailVerified);
    if (hasEmail && !verified) {
        throw new https_1.HttpsError("permission-denied", "Verify your email before signing in.");
    }
});
/** Callable to resend the verification email */
exports.resendVerificationEmail = (0, https_1.onCall)(async (request) => {
    var _a;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "Sign in first.");
    const rec = await admin.auth().getUser(uid);
    if (!rec.email)
        throw new https_1.HttpsError("failed-precondition", "No email.");
    if (rec.emailVerified)
        return { message: "Already verified." };
    const acs = {
        url: "https://pawpal-de6dd.firebaseapp.com/",
        handleCodeInApp: true,
    };
    const link = await admin.auth().generateEmailVerificationLink(rec.email, acs);
    return { message: "Verification email sent.", link };
});
/**
 * Set a user's role (0=user, 1=admin) and mirror to custom claims.
 * Only callable by an existing admin (custom claim admin=true).
 */
const SEED_ADMINS = new Set([
    // Add your bootstrap admin emails here (server-side only)
    "admin@pawpal.app",
]);
exports.setUserRole = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d, _e, _f, _g;
    const caller = request.auth;
    if (!(caller === null || caller === void 0 ? void 0 : caller.uid))
        throw new https_1.HttpsError("unauthenticated", "Sign in first.");
    let isAdmin = !!((_a = caller.token) === null || _a === void 0 ? void 0 : _a.admin);
    const email = (_c = (_b = caller.token) === null || _b === void 0 ? void 0 : _b.email) === null || _c === void 0 ? void 0 : _c.toLowerCase();
    // Bootstrap path: seeded admin email OR role==1 in Firestore
    if (!isAdmin && (!email || !SEED_ADMINS.has(email))) {
        const db = (0, firestore_1.getFirestore)();
        try {
            const snap = await db.collection("users").doc(caller.uid).get();
            const role = (_e = (_d = snap.data()) === null || _d === void 0 ? void 0 : _d.role) !== null && _e !== void 0 ? _e : 0;
            isAdmin = role === 1;
        }
        catch (_h) {
            isAdmin = false;
        }
        if (!isAdmin) {
            throw new https_1.HttpsError("permission-denied", "Admins only.");
        }
    }
    const uid = (_f = request.data) === null || _f === void 0 ? void 0 : _f.uid;
    const role = (_g = request.data) === null || _g === void 0 ? void 0 : _g.role; // 0 or 1
    if (!uid || (role !== 0 && role !== 1)) {
        throw new https_1.HttpsError("invalid-argument", "Provide {uid, role: 0|1}");
    }
    // Prevent an admin from removing their own admin rights
    if (uid === caller.uid && role !== 1) {
        throw new https_1.HttpsError("failed-precondition", "You cannot remove your own admin role.");
    }
    // Update custom claims
    await admin.auth().setCustomUserClaims(uid, { admin: role === 1 });
    // Mirror to Firestore
    const db = (0, firestore_1.getFirestore)();
    await db.collection("users").doc(uid).set({
        role,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: true };
});
/**
 * Permanently delete a user's account and profile document.
 * Only callable by an admin (custom claim admin=true) or a seeded email.
 */
exports.deleteUserAccount = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d, _e, _f;
    const caller = request.auth;
    if (!(caller === null || caller === void 0 ? void 0 : caller.uid))
        throw new https_1.HttpsError("unauthenticated", "Sign in first.");
    let isAdmin = !!((_a = caller.token) === null || _a === void 0 ? void 0 : _a.admin);
    const email = (_c = (_b = caller.token) === null || _b === void 0 ? void 0 : _b.email) === null || _c === void 0 ? void 0 : _c.toLowerCase();
    if (!isAdmin && (!email || !SEED_ADMINS.has(email))) {
        const db = (0, firestore_1.getFirestore)();
        try {
            const snap = await db.collection("users").doc(caller.uid).get();
            const role = (_e = (_d = snap.data()) === null || _d === void 0 ? void 0 : _d.role) !== null && _e !== void 0 ? _e : 0;
            isAdmin = role === 1;
        }
        catch (_g) {
            isAdmin = false;
        }
        if (!isAdmin) {
            throw new https_1.HttpsError("permission-denied", "Admins only.");
        }
    }
    const uid = (_f = request.data) === null || _f === void 0 ? void 0 : _f.uid;
    if (!uid)
        throw new https_1.HttpsError("invalid-argument", "Provide {uid}");
    // Prevent an admin from deleting themselves accidentally
    if (uid === caller.uid) {
        throw new https_1.HttpsError("failed-precondition", "You cannot delete your own account.");
    }
    const db = (0, firestore_1.getFirestore)();
    // Best-effort: remove Firestore profile first, then delete auth user.
    try {
        await db.collection("users").doc(uid).delete();
    }
    catch (e) {
        // ignore Firestore delete failures here; proceed to delete auth user
    }
    await admin.auth().deleteUser(uid);
    return { ok: true };
});
//# sourceMappingURL=index.js.map
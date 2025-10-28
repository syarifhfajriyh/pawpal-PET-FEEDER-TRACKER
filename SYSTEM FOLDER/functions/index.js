const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.listUsers = functions.https.onCall(async (data, context) => {
  // Check auth
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Only authenticated users can list users",
    );
  }

  // Check if admin
  const userDoc = await admin.firestore().collection("users")
      .doc(context.auth.uid).get();

  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only administrators can list users",
    );
  }

  try {
    const list = [];
    let nextPageToken;

    do {
      const result = await admin.auth().listUsers(1000, nextPageToken);
      for (const user of result.users) {
        // skip admins
        const firestoreUser = await admin.firestore()
            .collection("users")
            .doc(user.uid)
            .get();

        if (!firestoreUser.exists) continue;
        const data = firestoreUser.data();

        if (data.deleted) continue;
        if (data.role === "admin") continue;

        list.push({
          uid: user.uid,
          email: user.email || "",
          displayName: user.displayName || data.displayName || "",
          role: data.role || "user",
          emailVerified: user.emailVerified,
          createdAt: data.createdAt || user.metadata.creationTime,
          profileImageUrl: data.profileImageUrl || "",
        });
      }
      nextPageToken = result.pageToken;
    } while (nextPageToken);

    return {users: list};
  } catch (error) {
    console.error("Error listing users:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

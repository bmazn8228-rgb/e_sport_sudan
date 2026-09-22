const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// 1. إشعار عند إنشاء بطولة جديدة
// ─────────────────────────────────────────────────────────────────────────────
exports.onTournamentAdded = functions.firestore
  .document("tournaments/{tournamentId}")
  .onCreate(async (snap, context) => {
    const tournamentData = snap.data();
    const tournamentTitle = tournamentData.title || tournamentData.name || 'جديدة';

    const payload = {
      notification: {
        title: "بطولة جديدة متاحة! 🏆",
        body: `تم فتح التسجيل لبطولة ${tournamentTitle}. سارع بالانضمام الآن!`,
      },
      data: {
        type: "new_tournament",
        tournamentId: context.params.tournamentId,
      }
    };

    try {
      const response = await admin.messaging().sendToTopic("tournaments", payload);
      console.log("Successfully sent tournament notification:", response);
      return null;
    } catch (error) {
      console.error("Error sending tournament notification:", error);
      return null;
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// 2. إشعار للمستخدم عند قبول طلب الإيداع
// ─────────────────────────────────────────────────────────────────────────────
exports.onDepositApproved = functions.firestore
  .document("transactions/{txId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if status changed from 'pending' to 'approved'
    if (before.status !== 'pending' || after.status !== 'approved') {
      return null;
    }

    const userId = after.userId;
    const amount = after.amount || 0;

    if (!userId) return null;

    try {
      // Get the user's FCM token
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${userId}`);
        return null;
      }

      const message = {
        notification: {
          title: "✅ تم قبول طلب شحن رصيدك!",
          body: `تمت إضافة ${amount} ج.س إلى محفظتك بنجاح.`,
        },
        data: {
          type: "deposit_approved",
          amount: amount.toString(),
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(message);
      console.log("Deposit approval notification sent:", response);
      return null;
    } catch (error) {
      console.error("Error sending deposit notification:", error);
      return null;
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// 3. إشعار لفريقي المباراة عند جدولتها
// ─────────────────────────────────────────────────────────────────────────────
exports.onMatchScheduled = functions.firestore
  .document("matches/{matchId}")
  .onCreate(async (snap, context) => {
    const match = snap.data();
    const teamAName = match.teamA || 'الفريق الأول';
    const teamBName = match.teamB || 'الفريق الثاني';
    const tournamentName = match.tournamentName || 'البطولة';

    // Get FCM tokens for both team leaders
    const teamsToNotify = [];
    if (match.teamALeaderId) teamsToNotify.push(match.teamALeaderId);
    if (match.teamBLeaderId) teamsToNotify.push(match.teamBLeaderId);

    if (teamsToNotify.length === 0) return null;

    try {
      const userDocs = await Promise.all(
        teamsToNotify.map(uid => admin.firestore().collection('users').doc(uid).get())
      );

      const tokens = userDocs
        .map(doc => doc.data()?.fcmToken)
        .filter(token => !!token);

      if (tokens.length === 0) return null;

      const payload = {
        notification: {
          title: "⚔️ مباراتك جاهزة!",
          body: `${teamAName} vs ${teamBName} في ${tournamentName}. استعد للمنافسة!`,
        },
        data: {
          type: "match_scheduled",
          matchId: context.params.matchId,
        },
      };

      const response = await admin.messaging().sendMulticast({ ...payload, tokens });
      console.log("Match scheduled notifications sent:", response.successCount, "success");
      return null;
    } catch (error) {
      console.error("Error sending match notification:", error);
      return null;
    }
  });


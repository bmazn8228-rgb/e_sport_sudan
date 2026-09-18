const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onTournamentAdded = functions.firestore
  .document("tournaments/{tournamentId}")
  .onCreate(async (snap, context) => {
    const tournamentData = snap.data();
    
    // Fallback title in case the document structure changes
    const tournamentTitle = tournamentData.title || tournamentData.name || 'جديدة';

    const payload = {
      notification: {
        title: "بطولة جديدة متاحة! 🏆",
        body: `تم فتح التسجيل لبطولة ${tournamentTitle}. سارع بالانضمام الآن!`,
      },
      data: {
        type: "urgent",
        tournamentId: context.params.tournamentId,
      }
    };

    try {
      // Send the push notification to everyone subscribed to the 'tournaments' topic
      const response = await admin.messaging().sendToTopic("tournaments", payload);
      console.log("Successfully sent automatic notification:", response);
      return null;
    } catch (error) {
      console.error("Error sending automatic notification:", error);
      return null;
    }
  });

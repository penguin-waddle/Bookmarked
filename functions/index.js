/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.addFavoriteToActivityFeed = functions.firestore
    .document("favorites/{favoriteId}")
    .onCreate(async (snap, context) => {
      try {
        const favorite = snap.data();

        // Create the activity feed item with book details
        return await admin.firestore().collection("activityFeed").add({
          userID: favorite.userID,
          bookID: favorite.bookID,
          book: {
            id: favorite.bookID, // Using bookID from favorite
            title: favorite.title, 
            author: favorite.author, 
            imageUrl: favorite.imageUrl
          },
          type: "favorite",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (error) {
        console.error("Error adding favorite to activity feed:", error);
        return null; 
      }
    });



exports.addReviewToActivityFeed = functions.firestore
.document("books/{bookId}/reviews/{reviewId}")
.onCreate(async (snap, context) => {
  try {
    const review = snap.data();

    // Fetch the book details
    const bookSnap = await admin.firestore().collection("books").doc(review.bookID).get();
    if (!bookSnap.exists) {
      console.error("Book not found!");
      return null; 
    }
    const bookData = bookSnap.data();

    // Create the activity feed item with book details
    return await admin.firestore().collection("activityFeed").add({
      userID: review.userID,
      bookID: review.bookID,  // Keeping bookID at root level for easy deletion
      book: {
        id: bookSnap.id,
        title: bookData.title,
        author: bookData.author,
        imageUrl: bookData.imageUrl
      },
      type: "review",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("Error adding review to activity feed:", error);
    return null; 
  }
});


exports.removeFavoriteFromActivityFeed = functions.firestore
    .document("favorites/{favoriteId}")
    .onDelete(async (snap, context) => {
      try {
        const favorite = snap.data();
        const feedItems = await admin.firestore().collection("activityFeed")
            .where("userID", "==", favorite.userID)
            .where("bookID", "==", favorite.bookID)
            .where("type", "==", "favorite")
            .get();

        const batch = admin.firestore().batch();
        feedItems.docs.forEach(doc => {
          const docRef = admin.firestore().collection("activityFeed").doc(doc.id);
          batch.delete(docRef);
        });
        return await batch.commit();

      } catch (error) {
        console.error("Error removing favorite from activity feed:", error);
        return null;
      }
    });

exports.removeReviewFromActivityFeed = functions.firestore
    .document("books/{bookId}/reviews/{reviewId}")
    .onDelete(async (snap, context) => {
      try {
        const review = snap.data();
        const feedItems = await admin.firestore().collection("activityFeed")
            .where("userID", "==", review.userID)
            .where("bookID", "==", review.bookID)
            .where("type", "==", "review")
            .get();

        const batch = admin.firestore().batch();
        feedItems.docs.forEach(doc => {
          const docRef = admin.firestore().collection("activityFeed").doc(doc.id);
          batch.delete(docRef);
        });
        return await batch.commit();

      } catch (error) {
        console.error("Error removing review from activity feed:", error);
        return null;
      }
    });



exports.updateActivityFeedOnBookChange = functions.firestore
.document("books/{bookId}")
.onUpdate(async (change, context) => {
  try {
    const newBookData = change.after.data();
    const oldBookData = change.before.data();
    
    // Check if the relevant fields (that are stored in activity feed) have changed
    if (newBookData.title !== oldBookData.title || newBookData.author !== oldBookData.author || newBookData.imageUrl !== oldBookData.imageUrl) {
      const bookId = change.after.id;
      const feedItems = await admin.firestore().collection("activityFeed").where("book.id", "==", bookId).get();

      const batch = admin.firestore().batch();
      feedItems.docs.forEach(doc => {
        const docRef = admin.firestore().collection("activityFeed").doc(doc.id);
        batch.update(docRef, {
          "book.title": newBookData.title,
          "book.author": newBookData.author,
          "book.imageUrl": newBookData.imageUrl
        });
      });
      
      return await batch.commit();
    } else {
      return null;
    }
  } catch (error) {
    console.error("Error updating activity feed on book change:", error);
    return null;
  }
});

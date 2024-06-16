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
const functions = require('firebase-functions/v1'); // Use the v1 API
const axios = require('axios');
const admin = require('firebase-admin');
admin.initializeApp();

exports.addFavoriteToActivityFeed = functions.firestore
    .document("favorites/{favoriteId}")
    .onCreate(async (snap, context) => {
        const favorite = snap.data();
        const userRecord = await admin.auth().getUser(favorite.userID);
        const displayEmail = userRecord.email.substring(0, 6); // Extract first 6 characters of the email

        // favorite.firestoreId is the Firestore ID of the book
        const bookRef = admin.firestore().collection("books").doc(favorite.firestoreId);
        const bookSnap = await bookRef.get();
        if (!bookSnap.exists) {
            console.error("Book not found with Firestore ID:", favorite.firestoreId);
            return null;
        }
        const book = bookSnap.data();

        // Create the activity feed item with dynamically fetched book details
        return admin.firestore().collection("activityFeed").add({
            displayEmail,
            userID: favorite.userID,
            bookID: favorite.firestoreId, // Store Firestore ID
            book: {
                id: favorite.firestoreId, // Firestore ID
                title: book.title,
                author: book.author,
                imageUrl: book.imageUrl
            },
            type: "favorite",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

exports.addReviewToActivityFeed = functions.firestore
.document("books/{bookId}/reviews/{reviewId}")
.onCreate(async (snap, context) => {
  try {
    const review = snap.data();
    const userRecord = await admin.auth().getUser(review.userID);
    const userEmail = userRecord.email;
    const displayEmail = userEmail.substring(0, 6);

    // Fetch the book details
    const bookSnap = await admin.firestore().collection("books").doc(review.firestoreId).get();
    if (!bookSnap.exists) {
      console.error("Book not found!");
      return null; 
    }
    const book = bookSnap.data();

    // Create the activity feed item with dynamically fetched book details
    return admin.firestore().collection("activityFeed").add({
        displayEmail,
        userID: review.userID,
        bookID: review.firestoreId, // Store Firestore ID
        book: {
            id: review.firestoreId, // Firestore ID
            title: book.title,
            author: book.author,
            imageUrl: book.imageUrl
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
        const { bookId } = context.params;
        const newBookData = change.after.data();

        // Update activity feed to reflect new book details
        const activityFeedUpdates = admin.firestore().collection("activityFeed")
            .where("bookID", "==", bookId)
            .get()
            .then(snapshot => {
                const batch = admin.firestore().batch();
                snapshot.forEach(doc => {
                    // Updating the following details in activity feed items
                    batch.update(doc.ref, {
                        "book.title": newBookData.title,
                        "book.author": newBookData.author,
                        "book.imageUrl": newBookData.imageUrl
                    });
                });
                return batch.commit();
            });

        // Wait for the activity feed updates to complete
        await Promise.all([activityFeedUpdates]);
    });

exports.getBooks = functions.https.onCall(async (data, context) => {
  const searchTerm = data.searchTerm;
  const apiKey = functions.config().googlebooks.key; 

  try {
      const response = await axios.get(`https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(searchTerm)}&key=${apiKey}`);
      // Wrap the books array in an object under the 'items' key
      return { items: response.data.items }; 
  } catch (error) {
      console.error("Error fetching books:", error);
      throw new functions.https.HttpsError('unknown', 'Failed to fetch books');
  }
});

exports.getBookByID = functions.https.onCall(async (data, context) => {
  const bookID = data.bookID;
  const apiKey = functions.config().googlebooks.key;

  try {
      const response = await axios.get(`https://www.googleapis.com/books/v1/volumes/${bookID}?key=${apiKey}`);
      
      // Extract the necessary data to match GoogleBookItem structure
      const bookData = response.data;
      const transformedData = {
          id: bookData.id,
          volumeInfo: {
              title: bookData.volumeInfo.title,
              authors: bookData.volumeInfo.authors,
              publishedDate: bookData.volumeInfo.publishedDate,
              publisher: bookData.volumeInfo.publisher,
              description: bookData.volumeInfo.description,
              pageCount: bookData.volumeInfo.pageCount,
              categories: bookData.volumeInfo.categories,
              imageLinks: {
                  smallThumbnail: bookData.volumeInfo.imageLinks?.smallThumbnail,
                  thumbnail: bookData.volumeInfo.imageLinks?.thumbnail
              },
              industryIdentifiers: bookData.volumeInfo.industryIdentifiers
                  ? bookData.volumeInfo.industryIdentifiers.map(identifier => {
                      return {
                          type: identifier.type,
                          identifier: identifier.identifier
                      };
                  })
                  : []
          }
      };

      return transformedData;
  } catch (error) {
      console.error("Error fetching book by ID:", error);
      throw new functions.https.HttpsError('unknown', 'Failed to fetch book by ID');
  }
});

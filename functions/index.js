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
const functions = require('firebase-functions/v1');
const axios = require('axios');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
const express = require('express');
admin.initializeApp();

exports.addFavoriteToActivityFeed = functions.firestore
    .document("favorites/{favoriteId}")
    .onCreate(async (snap, context) => {
      console.log("addFavoriteToActivityFeed triggered");
      try {
        const favorite = snap.data();
        console.log("Favorite data:", favorite);
        const userRecord = await admin.auth().getUser(favorite.userId);
        const userEmail = userRecord.email;
        const displayEmail = userEmail.substring(0, 6);
        console.log("User record fetched:", userRecord);

        const activityFeedItem = {
          displayEmail: displayEmail,
          userId: favorite.userId,
          bookID: favorite.bookID,
          book: {
            id: favorite.bookID,
            title: favorite.title,
            author: favorite.author,
            imageUrl: favorite.imageUrl
          },
          type: "favorite",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        };
        console.log("Activity feed item:", activityFeedItem);

        await admin.firestore().collection("activityFeed").add(activityFeedItem);
        console.log("Activity feed item added successfully");
      } catch (error) {
        console.error("Error adding favorite to activity feed:", error);
      }
    });

exports.addReviewToActivityFeed = functions.firestore
    .document("books/{bookId}/reviews/{reviewId}")
    .onCreate(async (snap, context) => {
      console.log("addReviewToActivityFeed triggered");
      try {
        const review = snap.data();
        console.log("Review data:", review);
        const userRecord = await admin.auth().getUser(review.userId);
        const userEmail = userRecord.email;
        const displayEmail = userEmail.substring(0, 6);
        console.log("User record fetched:", userRecord);

        const bookSnap = await admin.firestore().collection("books").doc(review.bookID).get();
        if (!bookSnap.exists) {
          console.error("Book not found!");
          return null;
        }
        const bookData = bookSnap.data();
        console.log("Book data:", bookData);

        const activityFeedItem = {
          displayEmail: displayEmail,
          userId: review.userId,
          bookID: review.bookID,
          book: {
            id: bookSnap.id,
            title: bookData.title,
            author: bookData.author,
            imageUrl: bookData.imageUrl
          },
          type: "review",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        };
        console.log("Activity feed item:", activityFeedItem);

        await admin.firestore().collection("activityFeed").add(activityFeedItem);
        console.log("Activity feed item added successfully");
      } catch (error) {
        console.error("Error adding review to activity feed:", error);
      }
    });



exports.removeFavoriteFromActivityFeed = functions.firestore
    .document("favorites/{favoriteId}")
    .onDelete(async (snap, context) => {
      try {
        const favorite = snap.data();
        const feedItems = await admin.firestore().collection("activityFeed")
            .where("userId", "==", favorite.userId)
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
            .where("userId", "==", review.userId)
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

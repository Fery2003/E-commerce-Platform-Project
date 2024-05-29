const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendCommentNotification = functions.firestore
    .document("products/{productId}/comments/{commentId}")
    .onCreate(async (snapshot, context) => {
      const comment = snapshot.data();
      const productId = context.params.productId;

      // Get the vendor's token
      const vendorDoc = await admin
          .firestore()
          .collection("vendor_tokens")
          .doc(productId)
          .get();

      if (!vendorDoc.exists) {
        console.log("No vendor token found for product:", productId);
        return;
      }

      const vendorToken = vendorDoc.data().token;

      // Create a notification payload
      const payload = {
        notification: {
          title: "New Comment",
          body: `${comment.username} commented: "${comment.comment}"`,
        },
      };

      // Send the notification
      await admin.messaging().send(vendorToken, payload);
      console.log("Notification sent to vendor:", vendorToken);
    });

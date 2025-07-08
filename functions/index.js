const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendChatMessageNotification = functions.firestore
    .document("chatrooms/{roomId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
      const messageData = snapshot.data();
      const roomId = context.params.roomId;
      const senderId = messageData.authorId;
      const messageText = messageData.text;
      const senderName = messageData.authorName;

      // 1. 채팅방의 사용자 목록을 가져옵니다.
      const chatRoomRef = admin.firestore().collection("chatrooms").doc(roomId);
      const chatRoomDoc = await chatRoomRef.get();
      console.log(chatRoomDoc);

      // 채팅방 문서가 없거나 사용자 목록이 비어있으면 종료
      if (!chatRoomDoc.exists || !chatRoomDoc.data().users || chatRoomDoc.data().status === 'disconnected') {
        console.log("Chat room not found or no users in chat room.");
        return null;
      }
      const usersInChatRoom = chatRoomDoc.data().users;

      // 2. 메시지를 보낸 사람을 제외한 상대방의 UID를 찾습니다.
      const receiverId = usersInChatRoom.find((uid) => uid !== senderId);
      if (!receiverId) {
        console.log("No receiver found for this chat room.");
        return null;
      }

      // 3. 상대방의 사용자 문서를 가져와 FCM 토큰을 확인합니다.
      const receiverUserRef = admin.firestore()
          .collection("users")
          .doc(receiverId);
      const receiverUserDoc = await receiverUserRef.get();

      // 상대방 문서가 없거나 FCM 토큰이 없으면 종료
      if (!receiverUserDoc.exists || !receiverUserDoc.data().fcmToken) {
        console.log("Receiver user document not found or no FCM token.");
        return null;
      }
      const receiverFCMToken = receiverUserDoc.data().fcmToken;

      // 4. 알림 페이로드를 구성합니다.
      const notificationPayload = {
        title: `${senderName}님이 메시지를 보냈습니다.`,
        body: messageText,
      };

      const dataPayload = {
        roomId: roomId,
        senderId: senderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // Flutter에서 알림 클릭 시 사용될 액션
      };

      // 5. FCM 메시지 객체를 생성합니다.
      const message = {
        token: receiverFCMToken,
        notification: notificationPayload,
        data: dataPayload,
      };

      // 6. FCM 메시지를 보냅니다.
      try {
        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);
        return null;
      } catch (error) {
        console.error("Error sending message:", error);
        return null;
      }
    });

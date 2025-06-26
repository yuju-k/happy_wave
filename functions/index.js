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
      const usersInChatRoom = chatRoomDoc.data().users;

      // 2. 메시지를 보낸 사람을 제외한 상대방의 UID를 찾습니다.
      const receiverId = usersInChatRoom.find((uid) => uid !== senderId);
      if (!receiverId) {
        console.log("No receiver found for this chat room.");
        return null;
      }

      // 3. 상대방의 사용자 문서를 가져와 FCM 토큰을 확인합니다.
      const receiverUserRef = admin.firestore().collection("users").doc(receiverId);
      const receiverUserDoc = await receiverUserRef.get();
      const receiverFCMToken = receiverUserDoc.data().fcmToken;

      if (!receiverFCMToken) {
        console.log("Receiver does not have an FCM token.");
        return null;
      }

      // 4. 알림 페이로드를 구성합니다. (이 payload는 notification과 data 부분을 담당)
      // ESLint의 'max-len' 오류를 피하기 위해 줄바꿈을 적용합니다.
      const notificationPayload = {
        title: `${senderName}님이 메시지를 보냈습니다.`,
        body: messageText,
        sound: "default",
      };

      const dataPayload = {
        roomId: roomId,
        senderId: senderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // 알림 클릭 시 사용될 액션
      };

      // 5. FCM 메시지를 보냅니다.
      try {
        // admin.messaging().send()에 전달할 message 객체 생성
        const message = {
          token: receiverFCMToken, // 수신자 FCM 토큰
          notification: notificationPayload, // 알림 본문 (제목, 내용, 소리 등)
          data: dataPayload, // 앱에서 처리할 추가 데이터
        };

        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);
        return null;
      } catch (error) {
        console.error("Error sending message:", error);
        return null;
      }
    });
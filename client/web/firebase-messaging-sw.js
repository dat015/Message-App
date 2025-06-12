importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging.js');

firebase.initializeApp({
  apiKey: "AIzaSyB0UhvWapeOzLxCvP6TxUzlWPRNbj5rz-Y",
  authDomain: "chat-app-19a46.firebaseapp.com",
  projectId: "chat-app-19a46",
  storageBucket: "chat-app-19a46.firebasestorage.app",
  messagingSenderId: "392468555608",
  appId: "1:392468555608:web:4a3ab25f614f70fb4c272d",
  measurementId: "G-PJCJCLZHXW"
});

const messaging = firebase.messaging();

// Xử lý thông báo nền
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png' // Sử dụng icon hiện có của dự án
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
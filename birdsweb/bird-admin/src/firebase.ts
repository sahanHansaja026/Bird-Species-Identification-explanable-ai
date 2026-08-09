// firebase.ts
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
// (optional) analytics
import { getAnalytics } from "firebase/analytics";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyDa1iGllM1VPAnZZoZj_y1_GHJr_olg_Eo",
  authDomain: "admin-7595b.firebaseapp.com",
  databaseURL: "https://admin-7595b-default-rtdb.firebaseio.com",
  projectId: "admin-7595b",
  storageBucket: "admin-7595b.firebasestorage.app",
  messagingSenderId: "378147682569",
  appId: "1:378147682569:web:8455341d254715ac40bbd8",
  measurementId: "G-J7MY0ZZMZF"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// ✅ Firestore database
export const db = getFirestore(app);

// (optional)
export const analytics = getAnalytics(app);
export const storage = getStorage(app);
// ===========================================
// firebase-config.js
// ===========================================

const firebaseConfig = {
  apiKey: "AIzaSyA_0GXMIhXS6UVNzGuMkCFeMKrhRqRBxFk",
  authDomain: "bmi-calculator-app-773d0.firebaseapp.com",
  projectId: "bmi-calculator-app-773d0",
  storageBucket: "bmi-calculator-app-773d0.firebasestorage.app",
  messagingSenderId: "376896073985",
  appId: "1:376896073985:web:9d40c7f8b355b44164ab00",
  measurementId: "G-74HGN43T27"
};

firebase.initializeApp(firebaseConfig);

let analytics = null;

function startAnalytics() {
  if (!analytics) {
    try {
      analytics = firebase.analytics();
      console.log("Firebase Analytics started.");
    } catch (e) {
      console.warn("Firebase Analytics could not be initialized:", e);
    }
  }
}

if (localStorage.getItem("cookieConsent") === "accepted") {
  startAnalytics();
}

window.addEventListener("storage", (event) => {
  if (event.key === "cookieConsent" && event.newValue === "accepted") {
    startAnalytics();
  }
});

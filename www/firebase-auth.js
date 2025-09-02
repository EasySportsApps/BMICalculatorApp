// =============================================================================
// firebase-auth.js
// =============================================================================

// =============================================================================
// FirebaseUI initialization
// =============================================================================

const ui = new firebaseui.auth.AuthUI(firebase.auth());

ui.start('#firebaseui-auth-container', {
  signInOptions: [
    firebase.auth.EmailAuthProvider.PROVIDER_ID,
    firebaseui.auth.AnonymousAuthProvider.PROVIDER_ID
  ],
  callbacks: {
    signInSuccessWithAuthResult: function(authResult) {
      const user = authResult.user;
      const isAnonymous = user.isAnonymous;

      if (!isAnonymous) {
        if (!user.emailVerified) {
          user.sendEmailVerification()
            .then(() => {
              const noticeDiv = document.getElementById("email_verification_notice");
              if (noticeDiv) {
                noticeDiv.style.display = "block";
              }

              const reloadBtn = document.getElementById("reload_after_verification_button");
              if (reloadBtn) {
                reloadBtn.style.display = "inline-block";
              }

              firebase.auth().signOut();
            })
            .catch((error) => {
              console.error("Error sending verification email:", error);
              const noticeDiv = document.getElementById("email_verification_notice");
              if (noticeDiv) {
                noticeDiv.innerHTML = '<i class="fa fa-exclamation-triangle" style="margin-right: 10px;"></i> You have not yet verified your email address.<br>Please check your email inbox or spam folder.';
                noticeDiv.style.display = "block";
              }

              const reloadBtn = document.getElementById("reload_after_verification_button");
              if (reloadBtn) {
                reloadBtn.style.display = "inline-block";
              }

              firebase.auth().signOut();
            });
        } else {
          document.getElementById("encryption_key_prompt").style.display = "block";
          window.pendingUser = user;
          window.pendingIsAnonymous = isAnonymous;
        }
      } else {
        Shiny.setInputValue("userLoggedIn", true);
        Shiny.setInputValue("userEmail", "Guest");
        Shiny.setInputValue("userUid", user.uid);
        Shiny.setInputValue("userIsAnonymous", true);
        Shiny.setInputValue("userData", [], { priority: "event" });
      }

      return false;
    }
  }
});

// =============================================================================
// Derive key using PBKDF2 after confirming encryption password
// =============================================================================

let derivedKey = null;

document.addEventListener("DOMContentLoaded", function() {

  document.getElementById("confirm_key_button").addEventListener("click", function() {
    const password = document.getElementById("encryption_key_input").value;
    const passwordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%])[A-Za-z\d!@#$%]{8,20}$/;

    if (!passwordPattern.test(password)) {
      alert("The personal encryption passwords must be 8-20 characters and include uppercase, lowercase, numbers, and special characters (e.g., !@#$%).");
      return;
    }

    derivedKey = CryptoJS.PBKDF2(password, CryptoJS.enc.Utf8.parse("fixedSalt"), {
      keySize: 256 / 32,
      iterations: 1000
    });

    document.getElementById("encryption_key_prompt").style.display = "none";

    const user = window.pendingUser;
    const isAnonymous = window.pendingIsAnonymous;
    if (!user || !derivedKey) return;

    const welcomePopup = document.getElementById("welcomePopup");
    const welcomeMessageElement = document.getElementById("welcomeMessage");

    let userName = "User";
    if (window.pendingUser && window.pendingUser.displayName) {
        userName = window.pendingUser.displayName;
    } else if (window.pendingUser && window.pendingUser.email) {
        userName = window.pendingUser.email.split('@')[0];
    }
    welcomeMessageElement.textContent = `Welcome, ${userName}!`;

    welcomePopup.style.display = "block";
    setTimeout(() => {
        welcomePopup.style.opacity = "1";
    }, 10);

    setTimeout(() => {
        welcomePopup.style.opacity = "0";
        setTimeout(() => {
            welcomePopup.style.display = "none";
        }, 500);
    }, 3000);

    Shiny.setInputValue("userLoggedIn", true);
    Shiny.setInputValue("userEmail", user.email || "Guest");
    Shiny.setInputValue("userUid", user.uid);
    Shiny.setInputValue("userIsAnonymous", isAnonymous);

    const db = firebase.firestore();

    function decrypt(text) {
      const bytes = CryptoJS.AES.decrypt(text, derivedKey, {
        mode: CryptoJS.mode.ECB,
        padding: CryptoJS.pad.Pkcs7
      });
      return bytes.toString(CryptoJS.enc.Utf8);
    }

    db.collection("users").doc(user.uid).collection("patients")
      .get()
      .then((querySnapshot) => {
        const data = [];
        querySnapshot.forEach((doc) => {
          const d = doc.data();
          data.push({
            firestore_id: doc.id,
            patientId: decrypt(d.patientId),
            sex: decrypt(d.sex),
            weight: parseFloat(decrypt(d.weight)),
            height: parseFloat(decrypt(d.height)),
            timestamp: d.timestamp ? d.timestamp.toMillis() : null
          });
        });
        Shiny.setInputValue("userData", data, { priority: "event" });
      });
  });

  document.getElementById("encryption_key_input").addEventListener("keydown", function(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      document.getElementById("confirm_key_button").click();
    }
  });

  document.getElementById("toggle_password_visibility").addEventListener("change", function() {
    const input = document.getElementById("encryption_key_input");
    if (this.checked) {
      input.type = "text";
    } else {
      input.type = "password";
    }
  });

});

// =============================================================================
// Encrypt before saving to Firestore
// =============================================================================
Shiny.addCustomMessageHandler("saveData", function (data) {
  const user = firebase.auth().currentUser;
  if (!user || (!derivedKey && !user.isAnonymous)) {
    console.error("User not logged in or encryption key missing.");
    return;
  }

  function encrypt(text) {
    return CryptoJS.AES.encrypt(text.toString(), derivedKey, {
      mode: CryptoJS.mode.ECB,
      padding: CryptoJS.pad.Pkcs7
    }).toString();
  }

  const db = firebase.firestore();

  let dataToSave;
  if (user.isAnonymous) {
    dataToSave = {
      patientId: data.patientId,
      sex: data.sex,
      weight: data.weight,
      height: data.height,
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    };
  } else {
    dataToSave = {
      patientId: encrypt(data.patientId),
      sex: encrypt(data.sex),
      weight: encrypt(data.weight),
      height: encrypt(data.height),
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    };
  }
  
  db.collection("users").doc(user.uid).collection("patients").add(dataToSave)
    .then((docRef) => {
      console.log("✅ Data saved to Firestore successfully with ID:", docRef.id);
      
      const newRecord = {
        firestore_id: docRef.id,
        patientId: data.patientId,
        sex: data.sex,
        weight: data.weight,
        height: data.height,
        timestamp: new Date().getTime()
      };
      
      Shiny.setInputValue("newRecordSaved", newRecord, { priority: "event" });

    }).catch((error) => {
      console.error("🔥 Error saving data to Firestore:", error);
    });
});

// =============================================================================
// Update existing data in Firestore
// =============================================================================

Shiny.addCustomMessageHandler("updateData", function(data) {
  const user = firebase.auth().currentUser;
  if (!user || (!derivedKey && !user.isAnonymous)) {
    console.error("User not logged in or encryption key missing for update.");
    return;
  }
  
  const db = firebase.firestore();
  
  function encrypt(text) {
    return CryptoJS.AES.encrypt(text.toString(), derivedKey, {
      mode: CryptoJS.mode.ECB,
      padding: CryptoJS.pad.Pkcs7
    }).toString();
  }
  
  const docId = data.firestore_id;
  if (!docId) {
      console.error("🔥 Firestore document ID is missing. Cannot update.");
      return;
  }

  let dataToUpdate;
  if (user.isAnonymous) {
      dataToUpdate = {
        patientId: data.patientId,
        sex: data.sex,
        weight: data.weight,
        height: data.height
      };
  } else {
      dataToUpdate = {
        patientId: encrypt(data.patientId),
        sex: encrypt(data.sex),
        weight: encrypt(data.weight),
        height: encrypt(data.height)
      };
  }
  
  db.collection("users").doc(user.uid).collection("patients").doc(docId)
    .update(dataToUpdate)
    .then(() => {
        console.log("✅ Document successfully updated in Firestore.");
    })
    .catch((error) => {
        console.error("🔥 Error updating document in Firestore:", error);
    });
});

// =============================================================================
// Delete data from Firestore
// =============================================================================

Shiny.addCustomMessageHandler("deleteDataOnly", function(data) {
  const user = firebase.auth().currentUser;
  if (!user) {
    console.error("🔥 ERROR: User is not authenticated. Cannot delete.");
    return;
  }

  const db = firebase.firestore();
  const docId = data.firestore_id;

  if (!docId) {
    console.error("🔥 ERROR: Firestore document ID is missing. Cannot delete.");
    return;
  }

  db.collection("users").doc(user.uid).collection("patients").doc(docId).delete()
    .then(() => {
      console.log("✅ SUCCESS: Document successfully deleted from Firestore (no re-fetch).");
    })
    .catch((error) => {
      console.error("🔥 FIREBASE ERROR while deleting document:", error);
    });
});

// =============================================================================
// Logout button functionality
// =============================================================================

document.getElementById("logoutButton")?.addEventListener("click", function () {
  firebase.auth().signOut().then(() => {
    window.location.reload();
  }).catch((error) => {
    alert("Logout error: " + error.message);
  });
});

// =============================================================================
// Reload button functionality (for unverified users)
// =============================================================================

document.getElementById("reload_after_verification_button")?.addEventListener("click", function () {
  firebase.auth().signOut().then(() => {
    window.location.reload();
  }).catch((error) => {
    alert("Error signing out: " + error.message);
  });
});
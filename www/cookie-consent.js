// ===========================================
// cookie-consent.js
// ===========================================

document.addEventListener("DOMContentLoaded", () => {
  const modal = document.getElementById("cookieConsentModal");
  const closeBtn = document.getElementById("closeCookieConsent");
  const acceptBtn = document.getElementById("acceptCookiesBtn");
  const rejectBtn = document.getElementById("rejectCookiesBtn");
  const configureBtn = document.getElementById("configureCookiesBtn");
  const configPanel = document.getElementById("cookieConfigPanel");
  const saveConfigBtn = document.getElementById("saveCookieSettingsBtn");

  const cookieConsent = localStorage.getItem("cookieConsent");
  if (!cookieConsent) {
    modal.style.display = "block";
  }

  function saveConsent(value, prefs = {}) {
    localStorage.setItem("cookieConsent", value);
    if (value === "configured") {
      localStorage.setItem("cookiePreferences", JSON.stringify(prefs));
    }
    modal.style.display = "none";

    if (window.Shiny) {
      Shiny.setInputValue("cookieConsent", value, { priority: "event" });
      Shiny.setInputValue("cookiePreferences", prefs, { priority: "event" });
    }
  }

  closeBtn.onclick = () => {
    modal.style.display = "none";
  };

  acceptBtn.onclick = () => {
    saveConsent("accepted", {
      essential: true,
      analytics: true,
      personalization: true
    });
  };

  rejectBtn.onclick = () => {
    saveConsent("rejected", {
      essential: true,
      analytics: false,
      personalization: false
    });
  };

  configureBtn.onclick = () => {
    if (configPanel.style.display === "none" || configPanel.style.display === "") {
      configPanel.style.display = "block";
    } else {
      configPanel.style.display = "none";
    }
  };

  saveConfigBtn.onclick = () => {
    const prefs = {
      essential: true,
      analytics: document.getElementById("analyticsCookies").checked,
      personalization: document.getElementById("personalizationCookies").checked
    };
    saveConsent("configured", prefs);
  };

  window.onclick = (event) => {
    if (event.target === modal) {
      modal.style.display = "none";
    }
  };
});
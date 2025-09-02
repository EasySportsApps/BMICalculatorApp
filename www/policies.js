// ===========================================
// policies.js
// ===========================================

document.addEventListener("DOMContentLoaded", function() {
  function setupModalHandlers(triggerId, modalId, closeId) {
    const trigger = document.getElementById(triggerId);
    const modal = document.getElementById(modalId);
    const closeBtn = document.getElementById(closeId);

    if (!trigger || !modal || !closeBtn) return;

    trigger.onclick = function(event) {
      event.preventDefault();
      modal.style.display = "block";
    };

    closeBtn.onclick = function() {
      modal.style.display = "none";
    };

    window.addEventListener("click", function(event) {
      if (event.target === modal) {
        modal.style.display = "none";
      }
    });
  }

  setupModalHandlers("legalNoticeLink", "legalNoticeModal", "closeLegalNotice");
  setupModalHandlers("privacyPolicyLink", "privacyPolicyModal", "closePrivacyPolicy");
  setupModalHandlers("cookiePolicyLink", "cookiePolicyModal", "closeCookiePolicy");
});

// ===========================================
// validate-decimals.js
// ===========================================

document.addEventListener('DOMContentLoaded', function () {
  const weightInput = document.getElementById('weight');
  const heightInput = document.getElementById('height');

  if (weightInput) {
    weightInput.addEventListener('input', function (e) {
      let value = e.target.value;
      if (value.includes('.')) {
        let parts = value.split('.');
        if (parts[1].length > 1) {
          e.target.value = parts[0] + '.' + parts[1].slice(0, 1);
        }
      }
    });
  }

  if (heightInput) {
    heightInput.addEventListener('input', function (e) {
      let value = e.target.value;
      if (value.includes('.')) {
        let parts = value.split('.');
        if (parts[1].length > 2) {
          e.target.value = parts[0] + '.' + parts[1].slice(0, 2);
        }
      }
    });
  }
});

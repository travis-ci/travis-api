document.addEventListener('DOMContentLoaded', function() {
  $('#reset_changes_button').on('click', function(evt) {
    evt.preventDefault();
    window.location.reload();
  });
});

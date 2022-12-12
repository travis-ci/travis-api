document.addEventListener('DOMContentLoaded', function() {
  $('.custom-key-copy-button').on('click', function(evt) {
    const key = $(evt.target).attr('data-public-key');
    if (navigator.clipboard) {
      navigator.clipboard.writeText(key);
    }
  });
});

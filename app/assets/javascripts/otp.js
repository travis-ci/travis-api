$(document).ready(function(){
  if ($('.popup').length) {
    $('.otp').on('click', function(ev) {
      ev.preventDefault();
      $('.popup.is-hidden').removeClass('is-hidden');
      var $button = $(ev.target);

      $('#confirm-otp').on('click', function() {
        $button.closest("form").submit();
      });
    });
    $('.popup-close').on('click', function() {
      $('.popup').addClass('is-hidden');
    });
  }
});

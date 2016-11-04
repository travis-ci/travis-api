$(document).ready(function(){
  if ($('.popup').length) {
    $('.otp').on('click', function(ev) {
      ev.preventDefault();
      $('.popup.is-hidden').removeClass('is-hidden');
    });
    $('.popup-close').on('click', function() {
      $('.popup').addClass('is-hidden');
    });
  }
});

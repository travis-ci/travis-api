$(document).ready(function(){
  if ($('.popup').length) {
    $('.otp').on('click', function(ev) {
      ev.preventDefault();
      $('.popup.is-hidden').removeClass('is-hidden');

      if ($('.export').length && $('.purge').length) {
        var container = ev.currentTarget.parentElement.parentElement.parentElement;
        var className = container.className;

        if (className === 'export') {
          $('.purge .popup').addClass('is-hidden');
        }

        if (className === 'purge') {
          $('.export .popup').addClass('is-hidden');
        }
      }
    });

    $('.popup-close').on('click', function() {
      $('.popup').addClass('is-hidden');
    });
  }
});

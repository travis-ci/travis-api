$(document).ready(function(){
  if ($('.popup').length) {
    $('.otp').on('click', function(ev) {
      ev.preventDefault();
      // checking for siblings - lame workaround for gdpr otp vs admin list otp
      // if has siblings(admin page) need to use it otherwise last popup o page will be shown
      if ($(this).siblings('.popup').length) {
        $(this).siblings('.popup').removeClass('is-hidden');
      }
      else {
        $('.popup.is-hidden').removeClass('is-hidden');
      }
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

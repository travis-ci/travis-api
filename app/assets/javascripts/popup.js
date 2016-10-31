$(window).load(function() {

  if ($('.otp').length) {
    $('.otp').on('click', function(ev) {
      ev.preventDefault();
      $('.popup.is-hidden').removeClass('is-hidden');
      var $button = $(ev.target);

      $('#confirm-otp').on('click', function() {
        var input = $('#ot-password').val();
        $('.popup').addClass('is-hidden');
        $button.closest("form").find('#otp').val(input)
        $button.closest("form").submit();
      });
    });

    $('.popup-close').on('click', function() {
      $('.popup').addClass('is-hidden');
    });
  }

});

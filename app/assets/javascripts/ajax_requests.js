$(document).ready(function() {
  function displayFlash(kind, message) {
    $(".flashes").html('<p class="' + kind + '">' + message + '</p>');
  };

  $(".cancel-job, .cancel-build").on("ajax:success", function(e, data, status, xhr) {
    if (data.success) {
      $(this).find('.button').attr('value', 'Canceled').prop('disabled', true);
      displayFlash("notice", data.message);
    } else {
      displayFlash("error", data.message);
    }
  }).on("ajax:error", function(e, xhr, status, error) {
    displayFlash("error", error);
  });


  $(".restart-job, .restart-build").on("ajax:success", function(e, data, status, xhr) {
    if (data.success) {
      $(this).find('.button').attr('value', 'Restarted').prop('disabled', true);
      displayFlash("notice", data.message);
    } else {
      displayFlash("error", data.message);
    }
  }).on("ajax:error", function(e, xhr, status, error) {
    displayFlash("error", error);
  });

});

$(document).ready(function() {

  $(".cancel-job, .cancel-build").on("ajax:success", function(e, data, status, xhr) {
    if (data.success) {
      $(this).html('Canceled').addClass('disabled');
      $(".flashes").html('<p class="notice">' + data.message + '</p>');
    } else {
      $(".flashes").html('<p class="error">' + data.message + '</p>');
    }
  }).on("ajax:error", function(e, xhr, status, error) {
    $(".flashes").html('<p class="error">' + error + '</p>');
  });


  $(".restart-job, .restart-build").on("ajax:success", function(e, data, status, xhr) {
    if (data.success) {
      $(this).html('Restarted').addClass('disabled');
      $(".flashes").html('<p class="notice">' + data.message + '</p>');
    } else {
      $(".flashes").html('<p class="error">' + data.message + '</p>');
    }
  }).on("ajax:error", function(e, xhr, status, error) {
    $(".flashes").html('<p class="error">' + error + '</p>');
  });

});

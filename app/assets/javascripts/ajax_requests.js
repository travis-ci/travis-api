$(document).ready(function() {
  $(".cancel-job").on("ajax:success", function(e, data, status, xhr) {
    console.log(data);
  }).on("ajax:error", function(e, xhr, status, error) {
    console.log(error);
  });
});

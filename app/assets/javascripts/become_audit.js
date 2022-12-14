$(document).ready(function(){
  $(function() {
    $(".become-submit").on("click", function(e) {
      e.preventDefault();
      var userId = $('input[name="user_travis_id"]').val();
      $.post("/users/" + userId + "/become_as_audit");
      $(".become-button").submit();
    });

    $(".billing-become-submit").on("click", function(e) {
      e.preventDefault();
      var userId = $('input[name="user_travis_id"]').val();
      $.post("/users/" + userId + "/become_as_audit");
      $(".billing-button").submit();
    });
  });
})

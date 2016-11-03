$(document).ready(function () {
  $("body").on("click", '.pagination a', function(e){
    e.preventDefault();
    $(event.target).closest('section').find('.loading').append("<span class='loading-indicator'><i></i><i></i><i></i></span>");
    $.getScript(this.href);
    return false;
  });
});

$(document).ready(function () {
  $("body").on("click", '.pagination a', function(e){
    e.preventDefault();
    $.getScript(this.href);
    return false;
  });
});

document.addEventListener('DOMContentLoaded', function(){
  if (!window.location.hash && document.querySelector('.tab-link')) {
    var hash = document.querySelector('.tab-link').href;
    window.history.replaceState(undefined, undefined, hash);
    window.location = hash;
  }
}, false);

document.addEventListener('DOMContentLoaded', function(){
  if (!!location.hash) return;

  var link = document.querySelector('#tabs > .tab-link');
  if (link) link.click();
}, false);

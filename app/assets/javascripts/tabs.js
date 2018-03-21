document.addEventListener('DOMContentLoaded', function(){
  // TODO: Ideally this will be removed when there are no longer any
  // pages using anchor-based tabbed content
  if (!window.location.hash && document.querySelector('.tab-link')) {
    var hash = document.querySelector('.tab-link').href;
    window.history.replaceState(undefined, undefined, hash);
    window.location = hash;
  }

  var loading = $('<p/>').addClass('loading-indicator').html('<span/><span/><span/>');

  window.history.pushState({ href: window.location.href, content: 'main-content' }, null);

  $('a[data-remote][data-content]').on('ajax:send', function(xhr) {
    $('#' + this.dataset.content).html(loading);
  }).on('ajax:success', function(e, response, status, xhr) {
    window.history.pushState({ href: this.href, content: this.dataset.content }, null, this.href);
    $('#' + this.dataset.content).html(response);
  });

  $(function() {
    console.log(window.location.pathname);
  })
  $('.remote-tab-link').click(function(e) {
    console.log(e);
    $('#tabs a').removeClass('tab-active');
    $(this).addClass('tab-active');
  });

  $(window).on('popstate', function(e) {
    var state = e.originalEvent.state;
    if (state && state.hasOwnProperty('href') && state.hasOwnProperty('content')) {
      $.ajax({
        url: state.href,
        beforeSend: function(xhr) {
          $('#' + state.content).html(loading);
        }
      }).done(function(response) {
        $('#' + state.content).html(response);
      });
    }
  });
}, false);

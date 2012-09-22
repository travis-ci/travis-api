# Web Clients

When writing an in-browser client, you have to circumvent the browser's
[same origin policy](http://en.wikipedia.org/wiki/Same_origin_policy).
Generally, we offer two different approaches for this:
[Cross-Origin Resource Sharing](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) (aka CORS)
and [JSONP](http://en.wikipedia.org/wiki/JSONP). If you don't have any good
reason for using JSONP, we recommend you use CORS.

## Cross-Origin Resource Sharing

All API resources set appropriate headers to allow Cross-Origin requests. Be
aware that on Internet Explorer you might have to use a different interface to
send these requests.

    // using XMLHttpRequest or XDomainRequest to send an API request
    var invocation = window.XDomainRequest ? new XDomainRequest() : new XMLHttpRequest();

    if(invocation) {
      invocation.open("GET", "https://api.travis-ci.org/", true);
      invocation.onreadystatechange = function() { alert("it worked!") };
      invocation.send();
    }

In contrast to JSONP, CORS does not lead to any execution of untrusted code.

Most JavaScript frameworks, like [jQuery](http://jquery.com), take care of CORS
requests for you under the hood, so you can just do a normal *ajax* request.

    // using jQuery
    $.get("https://api.travis-ci.org/", function() { alert("it worked!") });

Our current setup allows the headers `Content-Type`, `Authorization`, `Accept` and the HTTP methods `HEAD`, `GET`, `POST`, `PATCH`, `PUT`, `DELETE`.

## JSONP

You can disable the same origin policy by treating the response as JavaScript.
Supply a `callback` parameter to use this.

    <script>
      function jsonpCallback() { alert("it worked!") };
    </script>
    <script src="https://api.travis-ci.org/?callback=jsonpCallback"></script>

This has the potential of code injection, use with caution.

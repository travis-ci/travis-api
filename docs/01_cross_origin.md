# Web Clients

When write an in-browsers client, you have to circumvent the browser's
[same origin policy](http://en.wikipedia.org/wiki/Same_origin_policy).
Generally, we offer two different approaches for this:
[Cross-Origin Resource Sharing](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) (aka CORS)
and [JSONP](http://en.wikipedia.org/wiki/JSONP). If you don't have any good
reason for using JSONP, we recommend you use CORS.

## Cross-Origin Resource Sharing

... some general docs here ...

In contrast to JSONP, CORS does not lead to any execution of untrusted code.

Most JavaScript frameworks, like [jQuery](http://jquery.com), take care of CORS
requests for you under the hood, so you can just do a normal *ajax* request.

Our current setup allows the headers `Content-Type`, `Authorization`, `Accept` and the HTTP methods `HEAD`, `GET`, `POST`, `PATCH`, `PUT`, `DELETE`.

## JSONP

... some docs here ...

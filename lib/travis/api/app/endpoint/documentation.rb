require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # Generated API documentation.
    class Documentation < Endpoint
      set prefix: '/docs'
      enable :inline_templates

      # HTML view for [/endpoints](#/endpoints/).
      get '/' do
        content_type :html
        endpoints = Endpoints.endpoints
        erb :index, {}, :endpoints => endpoints.keys.sort.map { |k| endpoints[k] }
      end

      helpers do
        def icon_for(verb)
          # GET, POST, PATCH, PUT, DELETE"
          case verb
          when 'GET'    then 'file'
          when 'POST'   then 'edit'
          when 'PATCH'  then 'wrench'
          when 'PUT'    then 'share'
          when 'DELETE' then 'trash'
          else 'question-sign'
          end
        end

        def slug_for(route)
          return route['uri'] if route['verb'] == 'GET'
          route['verb'] + " " + route['uri']
        end

        def docs_for(entry)
          markdown(entry['doc']).
            gsub('<pre', '<pre class="prettyprint linenums lang-js pre-scrollable"').
            gsub(/<\/?code>/, '').
            gsub(/TODO:?/, '<span class="label label-warning">TODO</span>')
        end
      end
    end
  end
end

__END__

@@ index

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Travis API documentation</title>

    <!-- we might wanna change this -->
    <link href="http://twitter.github.com/bootstrap/assets/css/bootstrap.css" rel="stylesheet" />
    <link href="http://twitter.github.com/bootstrap/assets/js/google-code-prettify/prettify.css" rel="stylesheet" />
    <script src="http://twitter.github.com/bootstrap/assets/js/jquery.js"></script>
    <script src="http://twitter.github.com/bootstrap/assets/js/google-code-prettify/prettify.js"></script>
    <script src="http://twitter.github.com/bootstrap/assets/js/bootstrap.min.js"></script>

    <style type="text/css">
      header {
        position: relative;
        text-align: center;
        margin-top: 36px;
      }
      header h1 {
        text-shadow: 2px 2px 5px #000;
        margin-bottom: 9px;
        font-size: 81px;
        font-weight: bold;
        letter-spacing: -1px;
        line-height: 1;
      }
      header p {
        margin-bottom: 18px;
        font-weight: 300;
        font-size: 18px;
      }
      .page-header {
        margin-top: 90px;
      }
      .route {
        margin-bottom: 36px;
      }
      .page-header a {
        color: black;
      }
      .nav-list a {
        color: inherit !important;
      }
    </style>
  </head>

  <body onload="prettyPrint()">
    <div class="container">
      <div class="row">
        <header class="span12">
          <h1>The Travis API</h1>
          <p>All the routes, just waiting for you to build something awesome.</p>
        </header>
      </div>

      <div class="row">

        <aside class="span3">
          <div class="page-header">
            <h1>Navigation</h1>
          </div>
          <div class="well" style="padding: 8px 0;">
            <ul class="nav nav-list">
              <% endpoints.each do |endpoint| %>
                <li class="nav-header"><a href="#<%= endpoint['name'] %>"><%= endpoint['name'] %></a></li>
                <% endpoint['routes'].each do |route| %>
                  <li>
                    <a href="#<%= slug_for(route) %>">
                      <i class="icon-<%= icon_for route['verb'] %>"></i>
                      <tt><%= route['uri'] %></tt>
                    </a>
                  </li>
                <% end %>
              <% end %>
              <li class="divider"></li>
              <li class="nav-header">
                External Links
              </li>
              <li>
                <a href="https://travis-ci.org">
                  <i class="icon-globe"></i>
                  Travis CI
                </a>
              </li>
              <li>
                <a href="https://github.com/travis-ci/travis-api">
                  <i class="icon-cog"></i>
                  Source Code
                </a>
              </li>
              <li>
                <a href="https://github.com/travis-ci/travis-api/issues">
                  <i class="icon-list-alt"></i>
                  API issues
                </a>
              </li>
              <li>
                <a href="https://github.com/travis-ci/travis-ember">
                  <i class="icon-play-circle"></i>
                  Example Client
                </a>
              </li>
            </ul>
          </div>
        </aside>

        <section class="span9">

          <% endpoints.each do |endpoint| %>
            <div id="<%= endpoint['name'] %>">
              <div class="page-header">
                <h1>
                  <a href="#<%= endpoint['name'] %>"><%= endpoint['name'] %></a>
                </h1>
              </div>
              <% unless endpoint['doc'].to_s.empty? %>
                <%= docs_for endpoint %>
                <hr>
              <% end %>
              <% endpoint['routes'].each do |route| %>
                  <div class="route" id="<%= slug_for(route) %>">
                    <pre><h3><%= route['verb'] %> <%= route['uri'] %></h3></pre>
                    <% if route['scope'] %>
                      <p>
                        <h5>Required autorization scope: <span class="label"><%= route['scope'] %></span></h5>
                      </p>
                    <% end %>
                    <%= docs_for route %>
                  </div>
              <% end %>
            </div>
          <% end %>

        </section>
      </div>
    </div>
  </body>
</html>

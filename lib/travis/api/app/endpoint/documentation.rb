require 'travis/api/app'
require 'travis/api/app/endpoint/documentation/resources'

class Travis::Api::App
  class Endpoint
    # Generated API documentation.
    class Documentation < Endpoint
      set prefix: '/docs', public_folder: File.expand_path('../documentation', __FILE__), static_cache_control: :public
      enable :inline_templates, :static

      # Don't cache general docs in development
      configure(:development) { before { @@general_docs = nil } }

      # HTML view for [/endpoints](#/endpoints/).
      get '/' do
        cache_control :public
        content_type :html
        endpoints = Endpoints.endpoints
        erb :index, {}, endpoints: endpoints.keys.sort.map { |k| endpoints[k] }
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
          with_code_highlighting markdown(entry['doc'])
        end

        private

          def with_code_highlighting(str)
            str.
              gsub(/json\(:([^)]+)\)/) { "<pre>" + Resources::Helpers.json($1) + "</pre>" }.
              gsub('<pre', '<pre class="prettyprint linenums pre-scrollable"').
              gsub(/<\/?code>/, '').
              gsub(/TODO:?/, '<span class="label label-warning">TODO</span>')
          end

          def general_docs
            @@general_docs  ||= doc_files.map do |file|
              header, content = File.read(file).split("\n", 2)
              content         = markdown(content)
              subheaders      = []

              content.gsub!(/<h2>(.*)<\/h2>/) do
                subheaders << $1
                "<h2 id=\"#{$1}\">#{$1}</h2>"
              end

              header.gsub! /^#* */, ''
              { id: header, title: header, content: with_code_highlighting(content), subheaders: subheaders }
            end
          end

          def doc_files
            pattern = File.expand_path('../../../../../../docs/*.md', __FILE__)
            Dir[pattern].sort
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
    <meta charset="utf-8">
    <title>Travis CI API documentation</title>
    <link rel="stylesheet" href="<%= url('/css/style.css') %>" media="screen">
    <link href="http://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600,800" rel="stylesheet">
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
  </head>

  <body>
    <div id="navigation">
      <div class="wrapper">
        <a href="http://travis-ci.org/" class="logo-home"><img src="http://about.travis-ci.org/images/travisci-small.png" alt="Travis Logo"></a>
        <ul>
          <li><a href="http://about.travis-ci.org/blog/">Blog</a></li>
          <li><a href="http://about.travis-ci.org/docs/">Documentation</a></li>
        </ul>
      </div>
    </div>

    <div id="content">
      <div class="wrapper">
        <div class="pad">
          <div id="main">
            <h2 class="title">The Travis CI API</h2>

            <% general_docs.each do |doc| %>
              <%= erb :entry, locals: doc %>
            <% end %>

            <% endpoints.each do |endpoint| %>
              <%= erb :entry, {},
                id: endpoint['name'],
                title: endpoint['name'],
                content: erb(:endpoint_content, {}, endpoint: endpoint) %>
            <% end %>
          </div>
          <div id="sidebar">
            <% general_docs.each do |doc| %>
              <h2><a href="#<%= doc[:id] %>"><%= doc[:title] %></a></h2>
              <ul>
              <% doc[:subheaders].each do |sub| %>
                <li><a href="#<%= sub %>"><%= sub %></a></li>
              <% end %>
              </ul>
            <% end %>

            <% endpoints.each do |endpoint| %>
              <h2><a href="#<%= endpoint['name'] %>"><%= endpoint['name'] %></a></h2>
              <ul>
              <% endpoint['routes'].each do |route| %>
                <li>
                  <a href="#<%= slug_for(route) %>">
                    <i class="icon-<%= icon_for route['verb'] %>"></i>
                    <tt><%= route['uri'] %></tt>
                  </a>
                </li>
              <% end %>
              </ul>
            <% end %>

            <h2>External Links</h2>
            <ul>
              <li><a href="https://travis-ci.org">Travis CI</a></li>
              <li><a href="https://github.com/travis-ci/travis-api">Source Code</a></li>
              <li><a href="https://github.com/travis-ci/travis-api/issues">API issues</a></li>
              <li><a href="https://github.com/travis-ci/travis-web">Example Client</a></li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    <footer>
      <div class="wrapper">
        <div class="large-6 columns left">
          <div id="travis-logo">
            <img src="http://about.travis-ci.org/images/travis-mascot-200px.png" id="travis-mascot">
          </div>
          <div id="travis-address">
            <p>© 2013 Travis CI GmbH,<br>Prinzessinnenstr. 20, 10969 berlin, Germany</p>
          </div>
        </div>

        <div class="large-6 columns right">
          <div id="footer-nav">
            <ul class="left">
              <li><a href="mailto:contact@travis-ci.com">Email</a></li>
              <li><a href="http://chat.travis-ci.com">Live Chat</a></li>
              <li><a href="http://about.travis-ci.org/docs">Docs</a></li>
              <li><a href="http://status.travis-ci.com">Status</a></li>
            </ul>
          </div>

          <div id="berlin-sticker">
            <img src="http://about.travis-ci.org/images/made-in-berlin-badge.png" id="made-in-berlin">
          </div>
        </div>
      </div>
    </footer>
  </body>
</html>


@@ endpoint_content
<% unless endpoint['doc'].to_s.empty? %>
  <%= docs_for endpoint %>
<% end %>
<% endpoint['routes'].each do |route| %>
  <div class="route" id="<%= slug_for(route) %>">
    <h3><%= route['verb'] %> <%= route['uri'] %></h3>
    <% if route['scope'] %>
      <p>
        <h5>Required authorization scope: <span class="label"><%= route['scope'] %></span></h5>
      </p>
    <% end %>
    <%= docs_for route %>
  </div>
<% end %>

@@ entry
<div id="<%= id %>">
  <h2><%= title %> <a class="toc-anchor" href="#<%= id %>">#</a></h2>
  <%= content %>
</div>


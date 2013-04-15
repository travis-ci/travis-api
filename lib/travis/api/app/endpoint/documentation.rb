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
    <title>Travis API documentation</title>

    <!-- we might wanna change this -->
    <!-- <link href="<%= url('/css/bootstrap.css') %>" rel="stylesheet" /> -->
    <!-- <link href="<%= url('/css/prettify.css') %>" rel="stylesheet" /> -->
    <link href="<%= url('/css/style.css') %>" rel="stylesheet" />
    <!-- <script src="<%= url('/js/jquery.js') %>"></script> -->
    <!-- <script src="<%= url('/js/prettify.js') %>"></script> -->
    <!-- <script src="<%= url('/js/bootstrap.min.js') %>"></script> -->
  </head>

  <body onload="prettyPrint()">
    <div id="navigation">
      <div class="wrapper">
        <a href="http://travis-ci.org" id="logo">travis-ci<span>.org</span></a>
        <ul>
          <li><a href="http://about.travis-ci.org/blog/">Blog</a></li>
          <li><a href="http://about.travis-ci.org/docs/">User Documentation</a></li>
        </ul>
      </div>
    </div>

    <div id="header">
      <div class="wrapper">
        <h1 class="riddle"><a href="/docs" title="Travis API">The Travis API</a></h1>
        <p>All the routes, just waiting for you to build something awesome.</p>
      </div>
    </div>

    <div id="content">
      <div class="wrapper">
        <div class="pad">
          <div id="main">
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
    <div id="footer">
      <div class="wrapper">
        <div class="box">
          <p>This site is maintained by the <a href="http://github.com/travis-ci">Travis CI community</a>. Feel free to <a href="http://github.com/travis-ci/travis-api">contribute</a>!</p>
        </div>
        <div class="box">
          <p>This design was kindly provided by the talented Ben Webster of <a href="http://www.plus2.com.au">Plus2</a>.</p>
        </div>
        <div class="box last">
          <ul>
            <li><a href="https://github.com/travis-ci" title="">Travis CI on GitHub</a></li>
            <li><a href="https://twitter.com/travisci" title="">Travis CI on Twitter</a></li>
          </ul>
        </div>
      </div>
    </div>
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
        <h5>Required autorization scope: <span class="label"><%= route['scope'] %></span></h5>
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


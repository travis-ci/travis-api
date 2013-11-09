module Travis::Api::App::Responders
  require 'securerandom'

  class Atom < Base
    ATOM_FEED_ERB = ERB.new(File.read(__FILE__).split("__END__").last.strip)

    def apply?
      if resource.is_a?(ActiveRecord::Relation) && resource.first.is_a?(Build)
        @builds = resource
      end
      super && @builds
    end

    def apply
      super

      ATOM_FEED_ERB.result(binding)
    end

    private

    def content_type
      'application/atom+xml;charset=utf-8'
    end

  end
end

__END__
<?xml version="1.0" encoding="utf-8"?>
 
<feed xmlns="http://www.w3.org/2005/Atom">
 
  <title><%= @builds.first.repository.slug %> Builds</title>
  <link href="<%= endpoint.url %>" rel = "self" />
  <id>urn:uuid:<%= SecureRandom.uuid %></id>
  <updated><%= DateTime.now.strftime %></updated>
 
  <% @builds.each do |build| %>
  <entry>
    <title><%= build.repository.slug %> Build #<%= build.number %></title>
    <link href="" />
    <id>urn:uuid:<%= SecureRandom.uuid %></id>
    <updated><%= build.finished_at || build.started_at %></updated>
    <summary type="html">
    &lt;p&gt;
      <%= build.commit.message %> (<%= build.commit.committer_name %>)
      &lt;br/&gt;&lt;br/&gt;
      State: <%= build.state %>
      &lt;br/&gt;
      Started at: <%= build.started_at ? build.started_at : 'not started' %>
      &lt;br/&gt;
      Finished at: <%= build.finished_at ? build.finished_at :
        build.started_at ? 'still running' : 'not started' %>
    &lt;/p&gt;
    </summary>
    <author>
      <name><%= build.commit.committer_name %></name>
    </author>
  </entry>
  <% end %>
 
</feed>
module Travis::Api::App::Responders
  # This XML responder is used if the resource is a Repository, or a collection
  # of Repositories.
  # It returns XML data conforming to Multiple Project Summary Reporting Standard,
  # as explained in http://confluence.public.thoughtworks.org/display/CI/Multiple+Project+Summary+Reporting+Standard
  class Xml < Base
    TEMPLATE_ERB = ERB.new <<-EOF
<Projects>
<% @resource.each do |r| %>
  <Project
    name="<%= r.slug %>"
    activity="<%= ACTIVITY[r.last_build.state.to_sym] || ACTIVITY[:default] %>"
    lastBuildStatus="<%= STATUS[r.last_build.state.to_sym] || STATUS[:default]  %>"
    lastBuildLabel="<%= r.last_build.try(:number) %>"
    lastBuildTime="<%= r.last_build.finished_at.try(:strftime, '%Y-%m-%dT%H:%M:%S.%L%z') %>"
    webUrl="https://<%= Travis.config.client_domain %>/<%= r.slug %>"
  </Project>
<% end %>
</Projects>
    EOF

    STATUS = {
      default: 'Unknown',
      passed:  'Success',
      failed:  'Failure',
      errored: 'Error',
      canceld: 'Canceled',
    }

    ACTIVITY = {
      default: 'Sleeping',
      started: 'Building'
    }

    def apply?
      @resource = Array(resource)
      super && @resource.first.is_a?(Repository)
    end

    def apply
      super

      TEMPLATE_ERB.result(binding)
    end

    private

      def content_type
        'application/xml;charset=utf-8'
      end
  end
end

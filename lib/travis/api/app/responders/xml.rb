module Travis::Api::App::Responders
  # This XML responder is used if the resource is a Repository, or a collection
  # of Repositories.
  # It returns XML data conforming to Multiple Project Summary Reporting Standard,
  # as explained in http://confluence.public.thoughtworks.org/display/CI/Multiple+Project+Summary+Reporting+Standard
  class Xml < Base
    TEMPLATE_ERB = ERB.new <<-EOF
<Projects>
<% @resource.each do |repository| %>
  <% next if build(repository).nil? -%>
  <Project
    name="<%= r.slug %>"
    activity="<%= ACTIVITY[build(repository).state.to_sym] || ACTIVITY[:default] %>"
    lastBuildStatus="<%= STATUS[build(repository).state.to_sym] || STATUS[:default]  %>"
    lastBuildLabel="<%= build(repository).try(:number) %>"
    lastBuildTime="<%= build(repository).finished_at.try(:strftime, '%Y-%m-%dT%H:%M:%S.%L%z') %>"
    webUrl="https://<%= Travis.config.client_domain %>/<%= r.slug %>" />
<% end %>
</Projects>
    EOF

    STATUS = {
      default: 'Unknown',
      passed:  'Success',
      failed:  'Failure',
      errored: 'Error',
      canceled: 'Canceled',
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

    def branch
      params[:branch]
    end

    def build(repository)
      if branch.present?
        repository.last_complete_build(branch)      
      else
        repository.last_build
      end
    end

    private

      def content_type
        'application/xml;charset=utf-8'
      end
  end
end

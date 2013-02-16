module Travis::Api::App::Responders
  class Xml < Base
    TEMPLATE = File.read(__FILE__).split("__END__").last.strip

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

    def apply
      halt TEMPLATE % data
    end

    private

      def data
        {
          name:     resource.slug,
          url:      [Travis.config.domain, resource.slug].join('/'),
          activity: activity,
          label:    last_build.try(:number),
          status:   status,
          time:     last_build.finished_at.try(:strftime, '%Y-%m-%dT%H:%M:%S.%L%z')
        }
      end

      def status
        STATUS[last_build.state.to_sym] || STATUS[:default]
      end

      def activity
        ACTIVITY[last_build.state.to_sym] || ACTIVITY[:default]
      end

      def last_build
        @last_build ||= resource.last_build
      end
  end
end

__END__

<Projects>
  <Project
    name="%{name}"
    activity="%{activity}"
    lastBuildStatus="%{status}"
    lastBuildLabel="%{label}"
    lastBuildTime="%{time}"
    webUrl="%{url}" />
</Projects>

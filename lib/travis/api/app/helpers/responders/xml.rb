module Travis::Api::App::Helpers::Responders
  class Xml < Base
    TEMPLATE = File.read(__FILE__).split("__END__").last.strip

    STATUS = {
      nil => 'Unknown',
      0 => 'Success',
      1 => 'Failure'
    }

    ACTIVITY = {
      nil => 'Sleeping',
      'started' => 'Building',
      'finished' => 'Sleeping'
    }

    def apply?
      options[:format] == 'xml'
    end

    def apply
      halt TEMPLATE % data
    end

    private

      def data
        {
          name:     resource.slug,
          url:      [Travis.config.domain, resource.slug].join('/'),
          activity: ACTIVITY[last_build.try(:state)],
          label:    last_build.try(:number),
          status:   STATUS[resource.last_build_result_on(request.params)],
          time:     last_build.finished_at.try(:strftime, '%Y-%m-%dT%H:%M:%S.%L%z')
        }
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

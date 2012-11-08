# TODO move to travis-core?

RSpec::Matchers.define :deliver_json_for do |resource, options = {}|
  match do |response|
    if response.status == 200
      actual = parse(response.body)
      expected = resource.is_a?(Hash) ? resource : Travis::Api.data(resource, options)

      failure_message_for_should do
        "expected\n\n#{actual}\n\nto equal\n\n#{expected}"
      end

      actual == expected
    else
      failure_message_for_should do
        "expected the request to be successful (200) but was #{response.status}"
      end
      false
    end
  end

  def parse(body)
    MultiJson.decode(body)
  end
end

RSpec::Matchers.define :deliver_result_image_for do |name|
  match do |response|
    actual = files.detect do |name, content|
      response.body.to_s.force_encoding('ascii') == content.to_s.force_encoding('ascii') # TODO ummmmmmmm?
    end
    actual = actual && actual[0]

    failure_message_for_should do
      "expected #{actual.inspect} to equal #{name.inspect}"
    end

    actual == name
  end

  def files
    files = Hash[*Dir['public/images/result/*.png'].map do |file|
      [File.basename(file, '.png'), File.read(file)]
    end.flatten]
  end
end

RSpec::Matchers.define :deliver_cc_xml_for do |repo|
  match do |response|
    body = response.body

    failure_message_for_should do
      "expected #{body} to be a valid cc.xml"
    end

    body.include?('<Projects>') && body.include?(%(name="#{repo.slug}"))
  end
end

RSpec::Matchers.define :redirect_to do |expected|
  match do |response|
    actual = response.headers['location'].to_s.sub('http://example.org', '')

    failure_message_for_should do
      "expected to be redirect to #{expected} but was not. status: #{response.status}, location: #{actual}"
    end

    failure_message_for_should_not do
      "expected not to be redirect to #{expected} but was."
    end

    actual == expected
  end
end

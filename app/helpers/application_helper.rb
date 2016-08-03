module ApplicationHelper
  def build_counts(owner)
    Travis::DataStores.redis.hgetall("builds:#{owner.github_id}").sort_by(&:first).map { |e| e.last.to_i }
  end

  def builds_provided_for(owner)
    Travis::DataStores.topaz.builds_provided_for(owner.id)
  end

  def describe(object)
    case object
    when ::User, ::Organization then object.name.present? ? "#{object.name} (#{object.login})" : object.login
    when ::Repository           then object.slug
    when ::Build, ::Job         then "#{object.repository.slug}##{object.number}"
    when ::Request              then "##{object.id}"
    else object.inspect
    end
  end

  def format_config(value)
    case value
    when Symbol
      format_config(value.to_s)
    when String
      value
    when Array
      content_tag(:ul) do
        value.each do |v|
          concat content_tag(:li, format_config(v))
        end
      end
    when Hash
      content_tag(:dl) do
        value.each do |k,v|
          concat content_tag(:dt, format_config(k), class: 'info-label')
          concat content_tag(:dl, format_config(v))
        end
      end
    else
      value.to_s
    end
  end

  def format_duration(seconds, hrs_suffix: " hrs", min_suffix: " min", sec_suffix: " sec")
    return "none" if seconds.nil?
    time = Time.at(seconds.to_i).utc.strftime("%H#{hrs_suffix} %M#{min_suffix} %S#{sec_suffix}")
    time.gsub(/\b00#{hrs_suffix} 00#{min_suffix} 0?|\b00#{hrs_suffix} 0?|\A0/, '')
  end

  def format_short_duration(seconds)
    format_duration(seconds, hrs_suffix: "h", min_suffix: "m", sec_suffix: "s")
  end

  def update_topaz(owner, builds, previous_builds)
    event = {
      timestamp: Time.now,
      owner: {
        id: owner.id,
        name: owner.name,
        login: owner.login,
        type: owner.class.name
      },
      data: {
        trial_builds_added: builds.to_i,
        previous_builds: previous_builds.to_i
      },
      type: :trial_builds_added
    }
    Travis::DataStores.topaz.update(event)
  end

end

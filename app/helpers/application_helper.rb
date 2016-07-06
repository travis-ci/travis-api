module ApplicationHelper
  def describe(object)
    case object
    when ::User, ::Organization then object.name.present? ? "#{object.name} (#{object.login})" : object.login
    when ::Repository           then object.slug
    when ::Build, ::Job         then "#{object.repository.slug}##{object.number}"
    else object.inspect
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

  def format_config(value)
    case value
      when Symbol
        format_config(value.to_s)
      when String
        h(value)
      when Array
        items = value.map { |v| "<li>#{format_config(v)}</li>" }.join
        "<ul>#{items}</ul>"
      when Hash
        items = value.map { |k,v| "<dt>#{format_config(k)}:</dt> <dl>#{format_config(v)}</dl>" }.join
        "<dl>#{items}</dl>"
      else
        h(value.to_s)
    end
  end
end

module ApplicationHelper
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
        h(value.inspect == "\"#{value.strip}\"" ? value : value.inspect)
      when Array
        items = value.map { |v| "<li>#{format_config(v)}</li>" }.join
        "<ul>#{items}</ul>"
      when Hash
        items = value.map { |k,v| "<li><b>#{format_config(k)}:</b> #{format_config(v)}</li>" }.join
        "<ul>#{items}</ul>"
      else
        h(value.inspect)
    end
  end
end

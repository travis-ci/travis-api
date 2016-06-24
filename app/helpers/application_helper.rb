module ApplicationHelper
  def format_duration(seconds, hrs_suffix: " hrs", min_suffix: " min", sec_suffix: " sec")
    return "none" if seconds.nil?
    time = Time.at(seconds.to_i).utc.strftime("%H#{hrs_suffix} %M#{min_suffix} %S#{sec_suffix}")
    time.gsub(/\b00#{hrs_suffix} 00#{min_suffix} 0?|\b00#{hrs_suffix} 0?|\A0/, '')
  end

  def format_short_duration(seconds)
    format_duration(seconds, hrs_suffix: "h", min_suffix: "m", sec_suffix: "s")
  end
end

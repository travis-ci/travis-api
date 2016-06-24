module ApplicationHelper
  def format_duration(seconds, hrs_suffix: " hrs", min_suffix: " min", sec_suffix: " sec")
    hours, minutes, seconds = Time.at(seconds.to_i).utc.strftime("%H:%M:%S").split(':').map(&:to_i)

    [].tap do |parts|
      parts << "#{hours}#{hrs_suffix}" unless hours.zero?
      parts << "#{minutes}#{min_suffix}" unless minutes.zero?
      parts << "#{seconds}#{sec_suffix}" unless seconds.zero?
    end.join(' ')
  end

  def format_short_duration(seconds)
    format_duration(seconds, hrs_suffix: "h", min_suffix: "m", sec_suffix: "s")
  end
end

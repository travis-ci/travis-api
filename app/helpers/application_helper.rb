module ApplicationHelper
  def format_duration(seconds, hrs_suffix: "hrs", min_suffix: "min", sec_suffix: "sec")
    return "none" if seconds.nil?
    Time.at(seconds.to_i).utc.strftime("%H #{hrs_suffix} %M #{min_suffix} %S #{sec_suffix}")
  end

  def format_short_duration(seconds)
    format_duration(seconds, hrs_suffix: "h", min_suffix: "m", sec_suffix: "s")
  end
end

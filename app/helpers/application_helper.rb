module ApplicationHelper
  def format_duration(seconds)
    return "none" if seconds.nil?
    seconds          = (Time.now - seconds).to_i if seconds.is_a? Time
    output           = []
    minutes, seconds = seconds.divmod(60)
    hours, minutes   = minutes.divmod(60)
    output << "#{hours  } hrs" if hours > 0
    output << "#{minutes} min" if minutes > 0
    output << "#{seconds} sec" if seconds > 0 or output.empty?
    output.join(" ")
  end

  def format_short_duration(seconds)
    format_duration(seconds).gsub(' hrs', 'h').gsub(' min', 'm').gsub(' sec', 's')
  end

  def describe(object)
    case object
    when ::User, ::Organization then object.name.present? ? "#{object.name} (#{object.login})" : object.login
    when ::Repository           then object.slug
    when ::Build, ::Job         then "#{object.repository.slug}##{object.number}"
    else object.inspect
    end
  end
end

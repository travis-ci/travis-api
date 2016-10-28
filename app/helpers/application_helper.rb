module ApplicationHelper
  def access_token(user)
    Travis::AccessToken.create(user: user, app_id: 2) if user
  end

  def check_trial_builds(owner)
    builds_remaining = Travis::DataStores.redis.get("trial:#{owner.login}")

    if builds_remaining
      "#{builds_remaining} trial builds"
    else
      'not in trial'
    end
  end

  def describe(object)
    case object.class.to_s
    when 'User', 'Organization' then object.name.present? ? "#{object.name} (#{object.login})" : object.login
    when 'Repository'           then object.slug
    when 'Build', 'Job'         then "#{object.repository.slug}##{object.number}"
    when 'Request'              then "##{object.id}"
    when 'NullRecipient'        then "everybody"
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

  def format_feature(feature)
    feature.gsub(/[\-_]/, ' ').gsub('travis yml', '.travis.yml')
  end

  def format_price(amount)
    number_to_currency(amount.to_f/100)
  end

  def format_short_duration(seconds)
    format_duration(seconds, hrs_suffix: "h", min_suffix: "m", sec_suffix: "s")
  end

  def title(page_title)
    content_for(:title) { page_title }
  end
end

FactoryGirl.define do
  factory :event_session_open, class: Hash do
    transient do
      session_id     { SecureRandom.uuid }
      stoken         { SecureRandom.hex(12) }
      stoken_ro      { "ro-#{SecureRandom.hex(12)}" }
      ssh_cmd_fmt    "ssh %s@tmate-aws.travis.net"
      web_url_fmt    "disabled"
      reconnected    false
      pubkey         "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmkI6dXmASqzN6yqHjOME5unKxOhJblZY2wja6tCLY002IHvY="
      ip_address     "74.64.123.124"
      client_version "2.2.1"
    end

    type       'session_open'
    userdata   'userdata'
    entity_id  { session_id }

    params { {
      'stoken'         => stoken,
      'stoken_ro'      => stoken_ro,
      'ssh_cmd_fmt'    => ssh_cmd_fmt,
      'web_url_fmt'    => web_url_fmt,
      'reconnected'    => reconnected,
      'pubkey'         => pubkey,
      'ip_address'     => ip_address,
      'client_version' => client_version,
    } }

    initialize_with { attributes.stringify_keys }
  end


  factory :event_session_close, class: Hash do
    transient do
      session_id { SecureRandom.uuid }
    end

    type       'session_close'
    userdata   'userdata'
    entity_id  { session_id }

    params { {} }

    initialize_with { attributes.stringify_keys }
  end
end

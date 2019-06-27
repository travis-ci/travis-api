FactoryGirl.define do
  factory :abuse do
    reason { 'Updated manually, through admin' }
    owner_type { 'User' }

    factory(:abuse_level_offender) do
      level { ::Abuse::LEVEL_OFFENDER }
    end

    factory(:abuse_level_fishy) do
      level { ::Abuse::LEVEL_FISHY }
    end

    factory(:abuse_level_not_fishy) do
      level { ::Abuse::LEVEL_NOT_FISHY }
    end
  end
end

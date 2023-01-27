# frozen_string_literal: true

FactoryBot.define do
  factory :permission_set_term do
    activated_at { nil }
    activated_by { nil }
    inactivated_at { nil }
    inactivated_by { nil }
    title { "Permission Set Terms" }
    body { "These are some terms" }
  end
end

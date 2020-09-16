# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    recipient { FactoryBot.create(:user) }
    type { "" }
    params { "" }
    read_at { "2020-09-15 16:36:30" }
  end
end

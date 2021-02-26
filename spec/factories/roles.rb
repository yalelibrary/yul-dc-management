# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    name { 'editor' }
    users { [association(:user)] }
    resource {association :admin_set}
  end
end

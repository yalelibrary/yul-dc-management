# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |e| "user#{e}@email.com" }
    password { 'testing123' }
  end
end

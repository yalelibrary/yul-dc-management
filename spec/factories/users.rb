# frozen_string_literal: true

FactoryBot.define do
  # User objects are created from data passed from CAS.
  # The only field we get is uid. All user objects are given the
  # provider "cas"
  factory :user do
    uid { FFaker::Internet.user_name }
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    provider { "cas" }
    factory :sysadmin_user do
      after(:create) { |user| user.add_role(:sysadmin) }
    end
  end
end

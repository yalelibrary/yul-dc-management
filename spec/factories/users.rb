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
    after(:create) do |user|
      brbl = AdminSet.find_by_key('brbl')
      sml = AdminSet.find_by_key('sml')
      user.add_role(:editor, brbl) if brbl
      user.add_role(:editor, sml) if sml
    end
    factory :sysadmin_user do
      after(:create) do |user|
        user.add_role(:sysadmin)
      end
    end
  end
end

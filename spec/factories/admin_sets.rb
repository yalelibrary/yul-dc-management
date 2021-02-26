# frozen_string_literal: true

FactoryBot.define do
  factory :admin_set do
    key { "MyString" }
    label { "MyString" }
    homepage { "http://test.com" }
  end
end

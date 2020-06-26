# frozen_string_literal: true

FactoryBot.define do
  factory :dependent_object do
    dependent_uri { "MyString" }
    parent_object { "" }
  end
end

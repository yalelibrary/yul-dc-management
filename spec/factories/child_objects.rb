# frozen_string_literal: true

FactoryBot.define do
  factory :child_object do
    oid { FFaker::Number.number(digits: 8) }
    caption { "MyString" }
    width { 1 }
    height { 1 }
    order { 1 }
    parent_object { nil }
  end
end

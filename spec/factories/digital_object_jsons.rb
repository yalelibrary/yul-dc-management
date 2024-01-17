# frozen_string_literal: true

FactoryBot.define do
  factory :digital_object_json do
    parent_object { nil }
    json { '{"test":"test"}' }
  end
end

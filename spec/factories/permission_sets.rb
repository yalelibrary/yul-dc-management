# frozen_string_literal: true

FactoryBot.define do
  factory :permission_set do
    label { "Permission Label" }
    key { "Permission Key" }
    max_queue_length { 1 }
  end
end

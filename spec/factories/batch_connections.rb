# frozen_string_literal: true

FactoryBot.define do
  factory :batch_connection do
    batch_process { nil }
    connectable { nil }
  end
end

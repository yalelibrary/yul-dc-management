# frozen_string_literal: true

FactoryBot.define do
  factory :ingest_event do
    reason { "MyString" }
    status { "MyString" }
    batch_connection { nil }
  end
end

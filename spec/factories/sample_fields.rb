# frozen_string_literal: true

FactoryBot.define do
  factory :sample_field do
    field_name { "MyString" }
    field_count { 1 }
    field_percent_of_total { "9.99" }
    metadata_sample { nil }
  end
end

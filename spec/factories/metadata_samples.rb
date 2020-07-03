# frozen_string_literal: true

FactoryBot.define do
  factory :metadata_sample do
    metadata_source { "MyString" }
    number_of_samples { 1 }
    seconds_elapsed { "9.99" }
  end
end

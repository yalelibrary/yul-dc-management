FactoryBot.define do
  factory :metadata_sample do
    metadata_source { "MyString" }
    number_of_samples { 1 }
    time_elapsed { "2020-07-03 14:41:46" }
  end
end

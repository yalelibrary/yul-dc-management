# frozen_string_literal: true

FactoryBot.define do
  factory :metadata_source do
    id { 1 }
    metadata_cloud_name { "ladybird" }
    display_name { "Ladybird" }
    file_prefix { "" }
  end
  factory :metadata_source_voyager do
    id { 2 }
    metadata_cloud_name { "ils" }
    display_name { "Voyager" }
    file_prefix { "V-" }
  end
  factory :metadata_source_aspace do
    id { 3 }
    metadata_cloud_name { "aspace" }
    display_name { "ArchiveSpace" }
    file_prefix { "AS-" }
  end
end

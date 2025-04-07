# frozen_string_literal: true

FactoryBot.define do
  factory :metadata_source do
    id { 1 }
    metadata_cloud_name { "ladybird" }
    display_name { "Ladybird" }
    file_prefix { "" }
    factory :metadata_source_voyager do
      id { 2 }
      metadata_cloud_name { "ils" }
      display_name { "Voyager" }
      file_prefix { "V-" }
    end
    factory :metadata_source_aspace do
      id { 3 }
      metadata_cloud_name { "aspace" }
      display_name { "ArchivesSpace" }
      file_prefix { "AS-" }
    end
    factory :metadata_source_sierra do
      id { 4 }
      metadata_cloud_name { "sierra" }
      display_name { "Sierra" }
      file_prefix { "S-" }
    end
    factory :metadata_source_alma do
      id { 5 }
      metadata_cloud_name { "alma" }
      display_name { "Alma" }
      file_prefix { "Al-" }
    end
  end
end

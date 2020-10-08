# frozen_string_literal: true

FactoryBot.define do
  factory :batch_process_event do
    batch_process { FactoryBot.create(:batch_process) }
    parent_object { FactoryBot.create(:parent_object) }
    queued { "2020-10-08" }
    metadata_fetched { "2020-10-08" }
    child_records_created { "2020-10-08" }
    ptiff_jobs_created { "2020-10-08" }
    iiif_manifest_saved { "2020-10-08" }
    indexed_to_solr { "2020-10-08" }
  end
end

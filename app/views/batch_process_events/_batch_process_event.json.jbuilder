# frozen_string_literal: true

json.extract! batch_process_event, :id, :batch_process_id, :parent_object_oid, :queued, :metadata_fetched,
              :child_records_created, :ptiff_jobs_created, :iiif_manifest_saved, :indexed_to_solr, :created_at, :updated_at
json.url batch_process_event_url(batch_process_event, format: :json)

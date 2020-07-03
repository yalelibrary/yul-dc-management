# frozen_string_literal: true

json.extract! metadata_sample, :id, :metadata_source, :number_of_samples, :seconds_elapsed, :created_at, :updated_at
json.url metadata_sample_url(metadata_sample, format: :json)
